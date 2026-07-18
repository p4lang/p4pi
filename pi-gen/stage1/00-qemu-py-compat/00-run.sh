#!/bin/bash -e

# Under QEMU ARM64 emulation, python3.9 segfaults (exit 139) when py3compile
# invokes it to determine the cache tag via `import imp; print(imp.get_tag())`.
# This causes postinst scripts for packages like python3-pil (a dependency of
# python3-picamera2) to fail, aborting the entire image build.
#
# Work around this by replacing py3compile (and py3clean) with no-ops for the
# full package-install window (starting in stage1). A companion script in
# stage3/99-restore-py3compile restores the originals so the final image
# retains a working py3compile.

stub_tool() {
	local TOOL_PATH="$1"
	if [ -f "${TOOL_PATH}" ] && [ ! -f "${TOOL_PATH}.qemu-bak" ]; then
		mv "${TOOL_PATH}" "${TOOL_PATH}.qemu-bak" || {
		echo "Error: Failed to backup ${TOOL_PATH}" >&2
		return 1
	}
		cat > "${TOOL_PATH}" << 'EOF'
#!/bin/sh
# Temporarily replaced during QEMU ARM image build – restored by stage3/99-restore-py3compile
exit 0
EOF
		chmod 755 "${TOOL_PATH}"
	fi
}

stub_tool "${ROOTFS_DIR}/usr/bin/py3compile"
stub_tool "${ROOTFS_DIR}/usr/bin/py3clean"
