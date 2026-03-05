---
layout: post
title: "Building the MT7921 WiFi Driver on OSMC (Raspberry Pi 4)"
permalink: /blog/2026-03-05-mt7921-wifi-driver-on-osmc-raspberry-pi-4/
date: 2026-03-05 12:00:00 +0100
categories: raspberry pi osmc wifi kernel driver
description: "A complete guide to backporting and building the MT7921 WiFi driver on OSMC's Raspberry Pi 4, where the mixed-architecture setup and older kernel make it anything but straightforward."
comments: true
published: true
---

Due to my housing arrangements, my Raspberry Pi 4 was left without Ethernet access. The Pi 4 does have a built-in WiFi chip (Broadcom BCM43455, 802.11ac), but it's single-stream — in practice you get around 80–115 Mbps. That's not enough when you want to stream media and download at the same time through OSMC.

So I ended up acquiring a [Fenvi FU-AX1800](https://www.fenvi.com/) USB WiFi adapter, which uses the MediaTek MT7921au chipset and supports WiFi 6 with 2x2 MIMO — a significant upgrade. But plugging it in revealed a different problem entirely.

The MT7921 is supported by the `mt7921u` kernel driver — but that driver was only added in **kernel 5.18**. OSMC ships with **kernel 5.15**, so the driver simply isn't there.

I've [backported the driver from 5.18.19](https://github.com/tomhudak/mt7921), but building it on OSMC is not a straightforward `make && make install` for two reasons:

1. **OSMC uses a mixed-architecture setup.** The Raspberry Pi 4 runs a **64-bit (aarch64) kernel** but OSMC's userland is **32-bit (armhf)**. All system tools — including `gcc` from `apt` — are 32-bit and cannot compile 64-bit kernel modules. You need an aarch64 cross-compiler, and OSMC's cross-compiler package ships inside a chroot that requires wrapper scripts to use.

2. **The kernel source tree needs manual preparation.** OSMC doesn't set up the `/lib/modules/<version>/build` symlink or copy the kernel `.config` by default, so the out-of-tree module build will fail unless you wire these up yourself and run `modules_prepare` first.

The steps below walk through the full process — from installing the toolchain to connecting to WiFi.

## Environment

- **Device**: Raspberry Pi 4 running OSMC
- **Kernel**: 5.15.92-1-osmc (aarch64 kernel, armhf userland)
- **USB Adapter**: Fenvi FU-AX1800 (MediaTek MT7921au, USB ID `0e8d:7961`)

## Step 1: Install build dependencies

```bash
sudo apt update
sudo apt install -y build-essential git libssl-dev bc file
```

If `libssl-dev` fails with a 404, download manually:

```bash
wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u4_armhf.deb -O /tmp/libssl1.1.deb
wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl-dev_1.1.1w-0+deb11u4_armhf.deb -O /tmp/libssl-dev.deb
sudo dpkg -i /tmp/libssl1.1.deb /tmp/libssl-dev.deb
```

## Step 2: Install kernel headers and source

Out-of-tree module builds need the kernel headers and source to compile against. OSMC packages these separately.

```bash
sudo apt install -y rbp464-headers-sanitised-5.15.92-1-osmc rbp464-source-5.15.92-1-osmc
```

> **Note**: Use `apt-cache search rbp464` if the exact version has changed.

## Step 3: Create the kernel build symlink

The kernel build system expects the source tree at `/lib/modules/<version>/build`, but OSMC doesn't create this symlink automatically.

```bash
sudo ln -sf /usr/src/rbp464-source-5.15.92-1-osmc /lib/modules/5.15.92-1-osmc/build
```

## Step 4: Install the cross-compiler

The kernel is arm64 but userland is armhf, so a cross-compiler is needed:

```bash
sudo apt install -y aarch64-toolchain-osmc
```

This installs a chroot-based toolchain at `/opt/osmc-tc/aarch64-toolchain-osmc/`.

## Step 5: Set up cross-compiler wrapper scripts

The OSMC toolchain is packaged inside a chroot, so the binaries can't find their dynamic linker and shared libraries when called directly from the host. Wrapper scripts set the correct `LD_LIBRARY_PATH` so the 64-bit compiler tools work outside the chroot.

```bash
# Create the dynamic linker symlink
sudo ln -sf /opt/osmc-tc/aarch64-toolchain-osmc/lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1

# Create wrapper scripts
sudo mkdir -p /usr/local/aarch64-cross
for tool in $(ls /opt/osmc-tc/aarch64-toolchain-osmc/usr/bin/aarch64-linux-gnu-* | xargs -n1 basename); do
  sudo tee /usr/local/aarch64-cross/$tool > /dev/null <<SCRIPT
#!/bin/sh
export LD_LIBRARY_PATH=/opt/osmc-tc/aarch64-toolchain-osmc/lib/aarch64-linux-gnu:/opt/osmc-tc/aarch64-toolchain-osmc/usr/lib/aarch64-linux-gnu
export PATH=/usr/local/aarch64-cross:\$PATH
exec /opt/osmc-tc/aarch64-toolchain-osmc/usr/bin/$tool "\$@"
SCRIPT
  sudo chmod +x /usr/local/aarch64-cross/$tool
done
```

## Step 6: Create assembler symlinks for GCC

When GCC invokes the assembler or linker internally, it looks for unprefixed tool names (`as`, `ld`, etc.) in `<sysroot>/usr/aarch64-linux-gnu/bin/`. The OSMC toolchain doesn't populate this directory, so GCC fails with "unknown assembler invoked". These symlinks fix that.

```bash
sudo mkdir -p /opt/osmc-tc/aarch64-toolchain-osmc/usr/aarch64-linux-gnu/bin
for tool in as ar ld ld.bfd ld.gold nm objcopy objdump ranlib readelf strip; do
  sudo ln -sf /opt/osmc-tc/aarch64-toolchain-osmc/usr/bin/aarch64-linux-gnu-$tool \
    /opt/osmc-tc/aarch64-toolchain-osmc/usr/aarch64-linux-gnu/bin/$tool
done
```

## Step 7: Copy kernel config and prepare for module building

The kernel source tree needs the running kernel's `.config` and a `modules_prepare` pass to generate the headers and scripts that out-of-tree builds depend on (e.g. `Module.symvers`, generated headers).

```bash
sudo cp /boot/config-5.15.92-1-osmc /usr/src/rbp464-source-5.15.92-1-osmc/.config

export LD_LIBRARY_PATH=/opt/osmc-tc/aarch64-toolchain-osmc/lib/aarch64-linux-gnu:/opt/osmc-tc/aarch64-toolchain-osmc/usr/lib/aarch64-linux-gnu

sudo -E make -C /usr/src/rbp464-source-5.15.92-1-osmc \
  ARCH=arm64 \
  CROSS_COMPILE=/usr/local/aarch64-cross/aarch64-linux-gnu- \
  modules_prepare
```

> **Note**: Ignore the `libarmmem.so` preload warnings — they are harmless (32-bit library being skipped by 64-bit processes).

## Step 8: Install firmware files

The MT7921 chipset requires firmware blobs that the driver uploads to the device at load time. OSMC's kernel 5.15 doesn't ship these since it has no built-in MT7921 support. Download them from the upstream linux-firmware repository.

```bash
sudo mkdir -p /lib/firmware/mediatek

sudo wget -O /lib/firmware/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin \
  https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin

sudo wget -O /lib/firmware/mediatek/WIFI_RAM_CODE_MT7961_1.bin \
  https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_RAM_CODE_MT7961_1.bin
```

## Step 9: Clone and build the mt7921 driver

```bash
cd ~
git clone https://github.com/tomhudak/mt7921.git
cd mt7921

export LD_LIBRARY_PATH=/opt/osmc-tc/aarch64-toolchain-osmc/lib/aarch64-linux-gnu:/opt/osmc-tc/aarch64-toolchain-osmc/usr/lib/aarch64-linux-gnu

make ARCH=arm64 \
  CROSS_COMPILE=/usr/local/aarch64-cross/aarch64-linux-gnu- \
  CONFIG_MT76_CONNAC_LIB=m \
  CONFIG_MT7921_COMMON=m \
  CONFIG_MT7921U=m
```

> **Critical**: You must pass `CONFIG_MT76_CONNAC_LIB=m` on the make command line. The kernel .config doesn't include this option, and without it the `mt76-connac-lib.ko` module won't be built, causing "Unknown symbol" errors when loading.

## Step 10: Install the modules

```bash
sudo -E make ARCH=arm64 \
  CROSS_COMPILE=/usr/local/aarch64-cross/aarch64-linux-gnu- \
  CONFIG_MT76_CONNAC_LIB=m \
  CONFIG_MT7921_COMMON=m \
  CONFIG_MT7921U=m \
  modules_install
```

> The `cp: -r not specified` errors at the end are harmless (firmware directory copy issue in the install script). The `.ko` modules are installed correctly.

Run depmod manually (it gets skipped due to missing `System.map`):

```bash
sudo /sbin/depmod -a
```

## Step 11: Load the driver

```bash
sudo /sbin/modprobe mt7921u
```

Verify the adapter appears:

```bash
ip link show
# You should see wlan1 (or similar)

dmesg | grep mt7921
# Should show: "mt7921u 1-1.3:1.0: HW/SW Version: ..."
# And: "WM Firmware Version: ..."
```

## Step 12: Configure autoload on boot

Without this, you'd have to manually `modprobe mt7921u` after every reboot.

```bash
echo 'mt7921u' | sudo tee /etc/modules-load.d/mt7921u.conf
```

## Step 13: Connect to WiFi

OSMC uses connman (not NetworkManager) for network management. A provisioning file tells connman how to connect to your network automatically.

```bash
sudo tee /var/lib/connman/your-wifi.config > /dev/null <<'EOF'
[service_your_wifi]
Type=wifi
Name=YOUR_SSID
Security=psk
Passphrase=YOUR_PASSWORD
AutoConnect=true
IPv4=dhcp
EOF
```

Then restart connman and connect:

```bash
sudo systemctl restart connman
connmanctl scan wifi
connmanctl services
# Find your network's service ID for wlan1 (identified by the MAC address)
connmanctl connect wifi_XXXX_YYYY_managed_psk
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `/lib/modules/.../build` not found | Redo step 3 (symlink) |
| `unknown assembler invoked` during modules_prepare | Redo step 6 (assembler symlinks for GCC) |
| `__uint128_t` error | Make sure you're using `ARCH=arm64` with the aarch64 cross-compiler |
| `bc: not found` during modules_prepare | `sudo apt install bc` |
| `Unknown symbol mt76_connac_*` when loading | Rebuild with `CONFIG_MT76_CONNAC_LIB=m` (step 9) |
| `Not registered` when connecting via connmanctl | Create a provisioning file (step 13) or restart connman |
| `libarmmem.so` preload warnings | Harmless — 32-bit library being skipped by 64-bit processes |
| Module doesn't load after reboot | Check `/etc/modules-load.d/mt7921u.conf` exists (step 12) |

## Built modules reference

The following kernel modules are installed in `/lib/modules/5.15.92-1-osmc/updates/`:

| Module | Purpose |
|--------|---------|
| `mt76/mt76.ko` | Core mt76 driver |
| `mt76/mt76-usb.ko` | mt76 USB transport |
| `mt76/mt76-connac-lib.ko` | mt76 connectivity library (MCU/MAC) |
| `mt76/mt7921/mt7921-common.ko` | MT7921 common driver |
| `mt76/mt7921/mt7921u.ko` | MT7921 USB driver (loads all deps) |

The source code for the backported driver is available at [github.com/tomhudak/mt7921](https://github.com/tomhudak/mt7921).
