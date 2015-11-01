#!/bin/bash

distro="jessie"
repo="http://debian.fastweb.it/debian"
output_dir="output"
linux_dir="$output_dir/linux-$distro"


# Prepare directories
mkdir -p $linux_dir
rm -rf $linux_dir/*
mkdir -p $linux_dir/media/boot
mkdir -p $linux_dir/usr/local/bin
mkdir -p $linux_dir/usr/bin


# Debootstrap
debootstrap --arch armhf --foreign --verbose --variant=minbase --include=wget ${distro} $linux_dir $repo


# Start second stage in chroot
#mkdir -p $linux_dir/etc/default
#cp /etc/timezone $linux_dir/etc
#TODO Check what this does and clean/fix/redo
cp ./fs_resize $linux_dir/usr/local/bin
cp /usr/bin/qemu-arm-static $linux_dir/usr/bin
cp ./second_stage.sh $linux_dir/second_stage.sh
chroot $linux_dir /usr/bin/qemu-arm-static -cpu cortex-a9 /bin/bash /second_stage.sh

# Clean up after second stage in chroot
rm $linux_dir/second_stage.sh
rm $linux_dir/usr/bin/qemu-arm-static
rm -rf $linux_dir/dev/*
rm -rf $linux_dir/proc/*
rm -rf $linux_dir/run/*
rm -rf $linux_dir/sys/*
rm -rf $linux_dir/tmp/*


# Copy over boot necessary files (kernel, modules and bins)
cp -rf ./h3_binaries/lib/modules $linux_dir/lib
cp -rf ./h3_binaries/lib/firmware $linux_dir/lib
chown -R root:root $linux_dir/lib/{modules,firmware}


# Create sdcard image
sync
./make_image.sh $linux_dir $output_dir
