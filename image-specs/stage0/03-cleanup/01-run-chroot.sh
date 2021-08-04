#!/bin/bash -e

# Remove apt-fast
apt-get remove -y -qq apt-fast
apt-key remove A2166B8D
rm -f /etc/apt/sources.list.d/apt-fast.list
apt-get autoremove -y
