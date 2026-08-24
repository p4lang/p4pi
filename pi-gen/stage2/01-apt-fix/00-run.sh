#!/bin/bash -e
on_chroot << CHEOF
apt-get remove -y apt-listchanges 2>/dev/null || true
CHEOF
