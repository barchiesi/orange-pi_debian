#!/bin/bash


if [ "${1}" = "" ]; then
    echo "Source directory not specified."
    echo "Usage: ${0} <linux_directory> <optional_output_dir>"
    exit 0
fi

linux_dir=$1
output_dir=$2

if [ "${2}" = "" ]; then
    output_dir="output"
fi


curr_date=`date +"%m-%d-%Y"`
sdcard="$output_dir/$curr_date-$linux_dir.img"
fatsize=64
_ext4size=`du -s $linux_dir | awk '{print $1}'`
linuxsize=$(expr $_ext4size / 1024 + 100)
image_linux="$output_dir/image_linux"
image_boot="$output_dir/image_boot"


dd if=/dev/zero of=${sdcard}_boot bs=1M count=$fatsize
dd if=/dev/zero of=${sdcard}_linux bs=1M count=$linuxsize
dd if=/dev/zero of=${sdcard} bs=1M count=$(expr $fatsize + $linuxsize + 30)
echo -e "o\nw" | fdisk ${sdcard}
partprobe -s ${sdcard}
sfat=40960
efat=$(expr $fatsize \* 1024 \* 1024 / 512 + $sfat - 1)
sext4=$(expr $efat + 1)
eext4=$(expr $linuxsize \* 1024 \* 1024 / 512 + $sext4)
echo -e "n\np\n1\n$sfat\n$efat\nn\np\n2\n$sext4\n$eext4\nt\n1\nb\nt\n2\n83\nw" | fdisk ${sdcard} > /dev/null 2>&1
linuxsize=$(expr $eext4 \* 512 / 1024 / 1024)
mkfs -t vfat -F 32 -n BOOT ${sdcard}_boot
vfatuuid=`blkid -s UUID -o value ${sdcard}_boot`
mkfs -F -t ext4 -L linux ${sdcard}_linux
ext4uuid=`blkid -s UUID -o value ${sdcard}_linux`
dd if=./h3_binaries/boot0_OPI.fex of=${sdcard} bs=1k seek=8 conv=notrunc
dd if=./h3_binaries/u-boot_OPI.fex of=${sdcard} bs=1k seek=16400 conv=notrunc
dd if=${sdcard} of=${sdcard}u bs=512 count=40960

mkdir -p $image_boot
mount ${sdcard}_boot $image_boot
cp ./h3_binaries/script.bin.OPI-PC* $image_boot
cp ./h3_binaries/uImage_OPI-2 $image_boot/uImage
cp ./h3_binaries/script.bin.OPI-2_1080p60 $image_boot/script.bin
umount $image_boot

mkdir -p $image_linux
mount ${sdcard}_linux $image_linux
rsync -r -t -p -o -g -x --delete -l -H -D --numeric-ids -s --stats $linux_dir/ $image_linux/
umount $image_linux

sync

dd if=${sdcard}u of=${sdcard}
dd if=${sdcard}_boot of=${sdcard} bs=1M conv=notrunc oflag=append
dd if=${sdcard}_linux of=${sdcard} bs=1M conv=notrunc oflag=append

rm -r $image_linux $image_boot ${sdcard}u ${sdcard}_boot ${sdcard}_linux
sync
