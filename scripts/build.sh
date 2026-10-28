#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo_dir/.work/libfprint"
build_dir="$repo_dir/.work/build"
revision=$(cat "$repo_dir/UPSTREAM_REVISION")
patch_file="$repo_dir/patches/0001-realtek-support-3274-9011.patch"

if [ "$(id -u)" -eq 0 ]; then
    echo "Build as your regular user; only installation requires root." >&2
    exit 1
fi
for tool in git meson ninja pkg-config cc c++; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing build tool: $tool" >&2; exit 1; }
done
mkdir -p "$repo_dir/.work"
if [ ! -d "$source_dir/.git" ]; then
    if [ -e "$source_dir" ]; then
        echo "Source path already exists without Git metadata: $source_dir" >&2
        exit 1
    fi
    git init -q "$source_dir"
    git -C "$source_dir" remote add origin https://gitlab.freedesktop.org/libfprint/libfprint.git
fi
if ! git -C "$source_dir" cat-file -e "$revision^{commit}" 2>/dev/null; then
    git -C "$source_dir" fetch --depth=1 origin "$revision"
fi
current_revision=$(git -C "$source_dir" rev-parse --verify HEAD 2>/dev/null || true)
if [ -z "$current_revision" ]; then
    git -C "$source_dir" checkout --detach "$revision"
elif [ "$current_revision" != "$revision" ]; then
    echo "Unexpected source revision; refusing to overwrite the source tree." >&2
    exit 1
fi
if git -C "$source_dir" apply --check "$patch_file" 2>/dev/null; then
    git -C "$source_dir" apply "$patch_file"
elif git -C "$source_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
    echo "Support patch is already applied."
else
    echo "Patch does not match this source tree; no files were overwritten." >&2
    exit 1
fi
if [ -f "$build_dir/build.ninja" ]; then
    meson setup --reconfigure "$build_dir" "$source_dir" \
        -Ddrivers=realtek -Ddoc=false -Dgtk-examples=false \
        -Dintrospection=false -Dinstalled-tests=false \
        -Dudev_rules=disabled -Dudev_hwdb=disabled
else
    meson setup "$build_dir" "$source_dir" \
        -Ddrivers=realtek -Ddoc=false -Dgtk-examples=false \
        -Dintrospection=false -Dinstalled-tests=false \
        -Dudev_rules=disabled -Dudev_hwdb=disabled
fi
meson compile -C "$build_dir" -j 2
meson test -C "$build_dir" --print-errorlogs fpi-device fpi-ssm
printf '\nBuilt: %s\n' "$build_dir/libfprint/libfprint-2.so.2.0.0"
