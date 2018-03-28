#!/bin/bash

# Print commands and stop on errors.
set -ex

# Setup environment variables.
KEYMAP="br-abnt2"
LANGUAGE="en_US.UTF-8"
DISK="/dev/sda"
COUNTRY="DE"
MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

# Setup keyboard layout.
loadkeys "${KEYMAP}"

# Ensure system clock is accurate.
timedatectl set-ntp true

# Setup mirrors.
curl -s "${MIRRORLIST}" |  sed 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

# Destroy magic strings and signatures on disk.
wipefs --all --force ${DISK}

# Setup partitions on disk.
sgdisk --clear --new=0:0:+512M --typecode=0:ef00 --new=0:0:0 --typecode=0:8e00 "${DISK}"

# Setup logical volume manager.
pvcreate "${DISK}2"
vgcreate system "${DISK}2"

# Setup logical volumes.
lvcreate --name root --size 15G system
lvcreate --name home --size 1G  system
lvcreate --name var  --size 2G system
lvcreate --name swap  --size 2048M system

# Format all filesystem.
mkfs.fat -F32 /dev/sda1
for volume in $( ls /dev/system/* | xargs -n 1 basename )
do
  if [ "${volume}" == "swap" ]
  then
    mkswap -L system-${volume} /dev/system/${volume}
  else
    mkfs.ext4 -L system-${volume} /dev/system/${volume}
  fi
done

# Mount the root filesystem.
mount -o noatime,errors=remount-ro /dev/system/root /mnt

# Mount the boot filesystem.
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot

# Mount all remaining filesystems.
for volume in $( ls /dev/system/* | xargs -n 1 basename )
do
  if [ "${volume}" != "swap" -a "${volume}" != "root" ]
  then
    mkdir /mnt/${volume}
    mount -o noatime,errors=remount-ro /dev/system/${volume} /mnt/${volume}
  fi
done

# Bootstrap the system.
pacstrap /mnt base openssh sudo lvm2

# Genereate fstab.
swapon /dev/system/swap
genfstab -t UUID /mnt >> /mnt/etc/fstab
swapoff /dev/system/swap

# Chroot into the new operating system.
arch-chroot /mnt /bin/bash
