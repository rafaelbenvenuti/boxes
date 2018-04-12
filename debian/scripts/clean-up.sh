#!/bin/bash

# Clean APT cache.
apt --yes autoremove
apt --yes clean

# Remove dhcp leases.
rm -rf /var/lib/dhcp/*.leases

# Zero out free space to save space.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Sync data to disk.
sync
