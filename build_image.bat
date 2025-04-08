@echo off
echo Current Working Directory: %cd%
set "goToDir=qnx710"

for /f "tokens=1* delims=%goToDir%" %%A in ("%cd%") do (
    set "qnxPath=%%A%goToDir%"
)

echo Setting up environment
call "%qnxPath%\qnxsdp-env.bat"

@echo off
echo Cleaning the build directory
make clean
rm -f "./images/host_image.cksum"

echo Building the QNX image
make ARCH=arm CROSS_COMPILE=qcc
if not exist "./images/ifs-rpi4.bin" (
    echo Build failed, ifs-rpi4.bin file does not exist.
    exit /b 1
)

echo Generating checksum file of the image
cksum ./images/ifs-rpi4.bin > ./images/host_image.cksum
if not exist "./images/host_image.cksum" (
    echo Checksum generation failed, host_image.cksum file does not exist.
    exit /b 1
)

echo Build and checksum generation completed successfully!
