#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later
set -eu
if [ "$(id -u)" -ne 0 ]; then
    echo "Root is required. Run this script with pkexec." >&2
    exit 1
fi
install_dir=/usr/local/lib/libfprint-3274-9011
override_dir=/etc/systemd/system/fprintd.service.d
systemctl stop fprintd.service
rm -f "$override_dir/3274-9011-local.conf"
rm -f "$install_dir/libfprint-2.so.2" "$install_dir/libfprint-2.so.2.0.0"
rmdir "$install_dir" 2>/dev/null || true
rmdir "$override_dir" 2>/dev/null || true
systemctl daemon-reload
printf '%s\n' 'Removed the local driver override; the packaged libfprint is active again.'
