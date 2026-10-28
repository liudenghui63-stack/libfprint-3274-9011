#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_lib="$repo_dir/.work/build/libfprint/libfprint-2.so.2.0.0"
install_dir=/usr/local/lib/libfprint-3274-9011
override_dir=/etc/systemd/system/fprintd.service.d
override_file="$override_dir/3274-9011-local.conf"
if [ "$(id -u)" -ne 0 ]; then
    echo "Root is required. Run: pkexec $repo_dir/scripts/install.sh" >&2
    exit 1
fi
if [ ! -f "$source_lib" ]; then
    echo "Build the driver with ./scripts/build.sh first." >&2
    exit 1
fi
systemctl cat fprintd.service >/dev/null
# Check runtime dependencies before changing the service configuration.
if ldd "$source_lib" | grep -q 'not found'; then
    echo "Missing runtime dependencies; inspect: ldd $source_lib" >&2
    exit 1
fi
install -d -m 0755 "$install_dir" "$override_dir"
install -m 0755 "$source_lib" "$install_dir/libfprint-2.so.2.0.0"
ln -sfn libfprint-2.so.2.0.0 "$install_dir/libfprint-2.so.2"
printf '%s\n' '[Service]' \
    'Environment="LD_LIBRARY_PATH=/usr/local/lib/libfprint-3274-9011"' \
    > "$override_file"
chmod 0644 "$override_file"
systemctl daemon-reload
systemctl stop fprintd.service
printf '%s\n' 'Installed. fprintd will load the local driver on its next activation.'
