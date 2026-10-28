# libfprint support for Realtek / Microarray `3274:9011`

[中文说明](README.zh-CN.md)

An experimental compatibility patch for libfprint's existing **Realtek MOC**
driver, with reproducible build and reversible installation scripts for Ubuntu.
This is a device adaptation of upstream libfprint, not a new fingerprint engine.

## Tested hardware

- **MECHREVO Wujie 14X 2026 Douzhan Edition**
  (**机械革命 无界14X 2026 斗战版**)
- USB ID: **`3274:9011`**
- USB product string: `Realtek USB2.0 Finger Print Bridge`
- Ubuntu 24.04, GNOME 46, x86_64
- Tested on one physical unit in September 2026

Check `lsusb -d 3274:9011` before installing. The laptop model alone is not a
compatibility guarantee; other units may contain different fingerprint modules.

## What the patch does

1. Adds USB ID `3274:9011` to the existing Realtek MOC driver.
2. Handles the device firmware returning status `0x01` after reading its Linux
   template table, where older supported devices return `0x00`.
3. Accepts that alternate status **only** for this USB ID and the template-table
   command, after validating the response size and occupied slot headers.
   All other non-zero statuses remain errors.

The patch is pinned to upstream revision
`6f9479c3d55f847c1b3769f28ceb99227f9858cf`.
See [the patch](patches/0001-realtek-support-3274-9011.patch) and
[upstream libfprint](https://gitlab.freedesktop.org/libfprint/libfprint).
This repository has not been merged into upstream.

## Verified and unverified behavior

On the tested machine, the adapted driver successfully opened and initialized
the device, read the Linux template table, enrolled a right-index fingerprint
through GNOME Settings, listed the saved print with fprintd, and completed a live
`fprintd-verify` with `verify-match`.

Build and upstream `fpi-device` / `fpi-ssm` unit tests pass. These tests do not
exercise the new firmware quirk; its hardware evidence is the enrollment and
verification above. The public patch omits temporary raw-response diagnostics
from the initial experiment.

Lock-screen authentication, PAM configuration, wrong-finger rejection,
suspend/resume, and reboot recovery have not been systematically verified.
There is no firmware updater or template-deletion tool in this repository.

## Build on Ubuntu 24.04

```sh
sudo apt install git build-essential meson ninja-build pkg-config \
  libglib2.0-dev libgusb-dev fprintd libpam-fprintd

git clone https://github.com/liudenghui63-stack/libfprint-3274-9011.git
cd libfprint-3274-9011
./scripts/build.sh
```

Build as a regular user. The script fetches the exact upstream revision, applies
the patch, compiles with two jobs, and runs the two core test suites. Sources and
build products stay in the ignored `.work/` directory. It is safe to run again;
an unexpected source revision is rejected rather than overwritten.

This build enables **only the Realtek driver**. While its override is active,
fprintd cannot use fingerprint readers handled by other libfprint drivers.

## Install and try it

Finish any ongoing fingerprint enrollment or authentication before installing.
Run from a graphical desktop session to get a system password dialog:

```sh
pkexec "$PWD/scripts/install.sh"
```

If PolicyKit is unavailable, use `sudo ./scripts/install.sh` in a normal terminal.
The installer:

- installs the runtime library in `/usr/local/lib/libfprint-3274-9011`;
- writes `/etc/systemd/system/fprintd.service.d/3274-9011-local.conf`;
- reloads systemd and stops fprintd so its next D-Bus activation loads this library.

It does not replace distribution files under `/usr/lib`, change PAM policy,
or modify stored fingerprint templates. No `make install` / `meson install`
is needed. Enrollment is a separate, explicit action in **Settings → Users →
Fingerprint Login**, or with `fprintd-enroll`. Afterwards, use `fprintd-verify`
to check your enrolled print. Keep password authentication available while testing.

## Uninstall

```sh
pkexec "$PWD/scripts/uninstall.sh"
```

The script removes only this project's library and service override, restoring
the distribution's libfprint on the next fprintd activation. It does not delete
enrolled templates. It also understands the installation paths used by the
original local experiment.

## Reporting results

Include the laptop model, USB ID, Ubuntu version, and which operation failed.
Do not post fingerprint templates, raw USB captures, or unredacted debug logs.
No biometric data, machine-specific logs, Windows driver binaries, or compiled
libraries are included in this repository.

## License and attribution

The patch adapts upstream libfprint's Realtek driver, copyright Realtek Corp.
and the respective upstream contributors. Original notices are preserved in
the upstream sources. The patch, helper scripts, and documentation are released
under **LGPL-2.1-or-later**; see [LICENSE](LICENSE).

Maintained by [liudenghui63-stack](https://github.com/liudenghui63-stack).
