#!/bin/sh

# requirement 1: ensure the server has image named 'ifs-rpi4.bin'
# requirement 2: ensure the server has checksum file of the image named 'host_image.cksum'
# requirement 3: ensure the scp command arguments provided are correct

# 1. check if boot_partition file is writable
BOOT_PARTITION_FILE="/sd_a/boot_partition"                      
if [ ! -w "$BOOT_PARTITION_FILE" ]
then
    echo "Boot partition file not writable or not existing. Aborting."
    exit 1
fi

# 2. identify the inactive partition 
CURR_BOOT=$(cat "$BOOT_PARTITION_FILE")
if [ "$CURR_BOOT" = "0" ]
then 
    INACTIVE_PARTITION="/sd_a"                                  
else 
    INACTIVE_PARTITION="/sd_b"                                   
fi
NEW_IMAGE="$INACTIVE_PARTITION/ifs-rpi4.bin"

# 3. check if inactive partition is mounted
if [ ! df "$INACTIVE_PARTITION" ]
then
    echo "Inactive partition not mounted. Aborting."
    exit 1
fi

# 4. remove the image and checksum files from the inactive partition
rm -f $INACTIVE_PARTITION/ifs-rpi4.bin $INACTIVE_PARTITION/*.cksum

# 5. download the file containing checksum result of the wanting image to this partition
echo "Please enter the server's SSH LOGIN in the format 'me@100.100.1.10"
read server
echo "Please enter the server full path of the DIRECTORY that contains both checksum file and image file '/path/to/dir'"
read remote_directory
CHECKSUM_FILE_ON_SERVER="$server:$remote_directory/host_image.cksum"
IMAGE_FILE_ON_SERVER="$server:$remote_directory/ifs-rpi4.bin"

scp $CHECKSUM_FILE_ON_SERVER $INACTIVE_PARTITION/host_image.cksum || {
    echo "Retrying checksum file download in 10 seconds..."
    sleep 10
    scp $CHECKSUM_FILE_ON_SERVER $INACTIVE_PARTITION/host_image.cksum || {
        echo "Checksum file download failed. Aborting."
        exit 1
    }
}

# 6. [manual power intervention before downloading new image] prompt the user to get ready for the downloading
echo "Press Enter to start downloading new image:"
read dummy

# 7. download the wanting image to the inactive partition
scp $IMAGE_FILE_ON_SERVER $NEW_IMAGE || {
    echo "Retrying image file download in 10 seconds..."
    sleep 10
    scp $IMAGE_FILE_ON_SERVER $NEW_IMAGE || {
        echo "Image file download failed. Aborting."
        exit 1
    }
}

# #  [manual power intervention during downloading new image]

# 8. verify the integrity of the new image:
# 8.1 get the checksum of the new image and save it to a file
# 8.2 compare the first two items (image checksum, image size) in the downloaded checksum file with the new image
# 8.3 if they are identical, prompt the user the new image is acquired successfully 
# 8.4 if they are not identical, prompt the user the new image is tempered and terminate this shell script
cd $INACTIVE_PARTITION
cksum ifs-rpi4.bin > /usr/tmp/target_image.cksum
read local_sum local_size local_rest < /usr/tmp/target_image.cksum
read host_sum host_size host_rest < host_image.cksum
if [ "$local_sum" = "$host_sum" ] && [ "$local_size" = "$host_size" ]
then
    echo "New image passed verification"
else
    echo "New image failed verification"
    echo "Expected: $host_sum $host_size"
    echo "Actual: $local_sum $local_size"
    echo "Aborting."
    exit 1
fi

# 9. rewrite the boot-partition file
if [ "$CURR_BOOT" = "0" ]
then
    echo "1" > $BOOT_PARTITION_FILE
else
    echo "0" > $BOOT_PARTITION_FILE
fi

# 10. shutdown the pi
echo "Image update via OTA done. Rebooting from $INACTIVE_PARTITION..."
shutdown