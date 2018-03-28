#!/bin/bash

# Print commands and stop on errors.
set -ex

# Setup configuration variables.
TIMEZONE="Europe/Berlin"
KEYMAP="br-abnt2"
LANGUAGE="en_US.UTF-8"
PASSWORD=$(openssl passwd -crypt 'password')

# Configure the hostname.
echo "unassigned-hostname.unassigned-domain" > /etc/hostname

# Configure the timezone.
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Configure the keymap.
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Setup the localization.
sed -i "s/#${LANGUAGE}/${LANGUAGE}/" /etc/locale.gen
locale-gen
echo "LANG=${LANGUAGE}" > /etc/locale.conf

# Synchronize hardware clock.
hwclock --systohc --utc

# Configure root user credentials.
usermod --password "${PASSWORD}" root

# Setup network interfaces.
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
ln -s '/usr/lib/systemd/system/dhcpcd@.service' '/etc/systemd/system/multi-user.target.wants/dhcpcd@eth0.service'

# Setup secure shell service.
sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
systemctl enable sshd.service

# Setup vagrant user.
/usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
/usr/bin/install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
/usr/bin/curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
/usr/bin/chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys

# enabling important services
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

# Include logical volume manager in hooks.
sed -i -e "/^HOOKS=/ s/)$/ sd-lvm2)/" /etc/mkinitcpio.conf
sed -i -e "/^HOOKS=/ s/udev/systemd/" /etc/mkinitcpio.conf
/usr/bin/mkinitcpio --preset linux

# Install bootloader.
bootctl --path=/boot install

# Setup update hook for systemd-boot.
mkdir /etc/pacman.d/hooks
cat >/etc/pacman.d/hooks/systemd-boot.hook <<EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF

# Configure the bootloader.
cat >/boot/loader/loader.conf <<EOF
default arch
timeout 3
editor  1
EOF

cat >/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/mapper/system-root
EOF
