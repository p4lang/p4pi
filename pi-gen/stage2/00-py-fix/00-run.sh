#!/bin/bash -e
on_chroot << CHEOF
# py3compile segfaults under QEMU emulation — stub it out during build
if [ -f /usr/bin/py3compile ]; then
    mv /usr/bin/py3compile /usr/bin/py3compile.real
    printf '#!/bin/sh\nexit 0\n' > /usr/bin/py3compile
    chmod +x /usr/bin/py3compile
fi
CHEOF
