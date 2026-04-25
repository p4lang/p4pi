#!/bin/bash -e

# Restore the real py3compile / py3clean that were replaced by a no-op stub
# in stage1/00-qemu-py-compat to work around QEMU ARM64 Python segfaults.
# Running this near the end of stage3 ensures the final image ships a fully
# functional py3compile for users who install Python packages at runtime.

restore_tool() {
	local TOOL_PATH="$1"
	if [ -f "${TOOL_PATH}.qemu-bak" ]; then
		mv "${TOOL_PATH}.qemu-bak" "${TOOL_PATH}" || {
		echo "Error: Failed to restore ${TOOL_PATH}" >&2
		return 1
	}
	else
		echo "Warning: ${TOOL_PATH}.qemu-bak not found; stub may not have been created." >&2
	fi
}

restore_tool "${ROOTFS_DIR}/usr/bin/py3compile"
restore_tool "${ROOTFS_DIR}/usr/bin/py3clean"
