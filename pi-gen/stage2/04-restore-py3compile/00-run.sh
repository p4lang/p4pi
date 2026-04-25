#!/bin/bash -e

# Restore the real py3compile / py3clean that were replaced by a no-op stub
# in stage2/00-qemu-py-compat to work around QEMU ARM64 Python segfaults.
# Running this at the end of stage2 ensures the final image ships a fully
# functional py3compile for users who install Python packages at runtime.

PY3COMPILE="${ROOTFS_DIR}/usr/bin/py3compile"
PY3CLEAN="${ROOTFS_DIR}/usr/bin/py3clean"

if [ -f "${PY3COMPILE}.qemu-bak" ]; then
	mv "${PY3COMPILE}.qemu-bak" "${PY3COMPILE}"
else
	echo "Warning: ${PY3COMPILE}.qemu-bak not found; py3compile stub may not have been created." >&2
fi

if [ -f "${PY3CLEAN}.qemu-bak" ]; then
	mv "${PY3CLEAN}.qemu-bak" "${PY3CLEAN}"
else
	echo "Warning: ${PY3CLEAN}.qemu-bak not found; py3clean stub may not have been created." >&2
fi
