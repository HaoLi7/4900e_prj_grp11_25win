# 25 Winter 4900E group project - Group 11
An implementation of A/B partitioning OTA update deployed on the Raspberry Pi 4 model B running QNX 7.1

## Directory structure tree:
<pre>
.
├── src
|   ├── rpi4.build: the buildfile of IFS image with some customazations
|   └── scripts
|       ├── build_image.bat: build the IFS image on the host
|       └── start_ota.sh: perform A/B OTA update on the target
├── uboot
|   ├── boot_partition: the boot indicator file (allows u-boot to boot from partition A by default)
|   ├── u-boot.bin: prebuilt U-Boot bootloader binary file (without any customazation)
|   └── uboot.env: U-Boot environment varianle file, stores commands and parameters
└── README.md
</pre>
