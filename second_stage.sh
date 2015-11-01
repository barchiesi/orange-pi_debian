#!/bin/bash


# Complete debian installation and install necessary packages.
/debootstrap/debootstrap --second-stage

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

cat >> /debconf-user-settings << _EOF_
locales locales/locales_to_be_generated multiselect     en_US.UTF-8 UTF-8
locales locales/default_environment_locale      select  en_US.UTF-8
_EOF_
debconf-set-selections /debconf-user-settings
rm /debconf-user-settings

apt-get -y update
apt-get -y upgrade
apt-get -y install locales
apt-get -y install dialog lsb-release --no-install-recommends
apt-get -y install ifupdown dbus
apt-get -y clean


# Configure interfaces
cat >> /etc/network/interfaces << _EOF_
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
_EOF_

cat >> /etc/hosts << _EOF_
127.0.0.1	localhost
127.0.1.1	debian

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
_EOF_


# Setup users
echo root:toor | chpasswd


# Create fstab
cat > /etc/fstab << _EOF_
/dev/mmcblk0p2  /  ext4  errors=remount-ro,noatime,nodiratime  0 1
/dev/mmcblk0p1  /media/boot  vfat  defaults  0 0
tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0
_EOF_
