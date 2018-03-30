#!/bin/bash

# Customize DebConf.
echo "debconf debconf/priority select critical" | debconf-set-selections
echo "debconf debconf/frontend select noninteractive" | debconf-set-selections
dpkg-reconfigure -f noninteractive -p critical debconf
