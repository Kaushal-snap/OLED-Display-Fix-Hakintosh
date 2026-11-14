# Hackintosh OLED Display Fix — WhateverXe Tiger Lake eDP Builder

Builds a custom **WhateverXe 0.8.2** kext with two community patches:

- `02-tgl-edp-keep-softsleep.patch` — keeps the firmware-trained Tiger Lake eDP link and adds the soft display-sleep behaviour described by the patch author.
- `03-redmibook-bpc-backlight.patch` — applies the RedmiBook BPC/backlight changes intended to address incorrect panel colour depth / backlight behaviour.

The script downloads the patches from the original RedmiBook project at build time, verifies that both apply cleanly, builds the kext, and copies the result to:

```text
~/WhateverXe_bpc.kext
```

## Tested configuration

The original report for this build is:

- ASUS VivoBook K15 OLED (K513EA)
- Intel Core i5-1135G7 (Tiger Lake), Iris Xe (device ID `9A49`)
- 8 GB RAM
- BIOS DVMT pre-allocated memory: 64 MB
- macOS Sequoia 15.8.3 (24H241)
- WhateverXe 0.8.2 + WhateverXe-Graphics package 0.4.4

**Important:** This is a community patch set, not a universal fix. It is intended for similar Tiger Lake eDP configurations, including compatible RedmiBook configurations. A matching CPU generation alone does not guarantee that a different laptop's panel, VBT, firmware, or backlight implementation is compatible. Make a backup of your working EFI and keep a bootable USB installer before testing.

## Requirements

Run on macOS with:

- Xcode Command Line Tools
- `git`
- `curl`
- `python3`

Install Command Line Tools if needed:

```bash
xcode-select --install
```

## Build

1. Download this repository.
2. Open Terminal and change into the downloaded folder.
3. Run:

```bash
chmod +x build_whateverxe_edp.sh
./build_whateverxe_edp.sh
```

The script builds WhateverXe 0.8.2 from source and writes the patched kext to `~/WhateverXe_bpc.kext`.

## Install the built kext

1. Back up your current EFI folder.
2. Mount the EFI partition you actually boot from.
3. Replace `EFI/OC/Kexts/WhateverXe.kext` with the generated `~/WhateverXe_bpc.kext`.
4. Check the kext entry and ordering in `config.plist` (WhateverXe must load after Lilu).
5. Reset NVRAM from the OpenCore picker and reboot.

Do not install the generated kext alongside another copy of WhateverXe. Do not enable WhateverGreen and WhateverXe together.

## Boot arguments from the original K513EA test

The original tested configuration used:

```text
-v debug=0x100 keepsyms=1 -allow3d -disablegfxfirmware -vi2c-force-polling -wexbeta -wex-tgl-edp-keep -wex-tgl-edp-softsleep
```

These arguments are configuration-specific. Do not blindly replace your existing boot arguments; merge only the required arguments and confirm that the switches exist in the exact kext build you are using.

The original setup also reported:

- `csr-active-config = 03080000`
- WhateverXe-Graphics package `0.4.4`
- Lilu `1.7.x`
- AMFIPass Mod `1.4.1` (follow the current WhateverXe project instructions; do not load two AMFIPass variants)

## Known limitations from the original test

- Without patch 03, the panel reportedly showed striped/noisy colours due to a BPC mismatch.
- HDR caused faded colours; HDR video was not supported in the original test. Keep HDR off for that configuration.
- If system sleep causes the panel to remain black, the original workaround was:

```bash
sudo pmset -a sleep 0
```

This disables system sleep; it is a workaround, not a general fix.

## Patch sources and credits

The patches are downloaded from:

- [WilliamAlexanda/macOS-for-RedmiBook-Pro-15-2021](https://github.com/WilliamAlexanda/macOS-for-RedmiBook-Pro-15-2021), directory `patches/whateverxe-0.8.0`
- [b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe) — upstream project and base version 0.8.2

All patch authors retain their original authorship and licensing. This repository provides a build helper and configuration notes; it does not claim ownership of the upstream patches or WhateverXe.

## Privacy before sharing an EFI

Never publish your personal SMBIOS values. Before sharing an EFI, remove or replace your own:

- `SystemSerialNumber`
- `MLB`
- `SystemUUID`
- `ROM`

Also inspect the EFI for personal identifiers, device-specific files, and other private data before uploading.

## Disclaimer

Use at your own risk. Keep a known-good EFI backup. A failed graphics configuration can leave the internal screen black; know how to boot from your recovery USB and restore the previous kext.
