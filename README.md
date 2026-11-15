# Hackintosh OLED Display Fix — WhateverXe Tiger Lake eDP Builder

Builds a custom **WhateverXe 0.8.2** kext with three community patches (02, 03 and the OLED DPCD/nits patch 05):

- `02-tgl-edp-keep-softsleep.patch` — keeps the firmware-trained Tiger Lake eDP link and adds the soft display-sleep behaviour described by the patch author.
- `03-redmibook-bpc-backlight.patch` — applies the RedmiBook BPC/backlight changes intended to address incorrect panel colour depth / backlight behaviour.
- `05-tgl-dpcd-backlight.patch` — adds the OLED eDP AUX/DPCD brightness-in-nits path described below.

The script downloads patches 02 and 03 from the original RedmiBook project and patch 05 from this repository at build time, verifies that they apply cleanly, builds the kext, and copies the result to:

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

The script builds WhateverXe 0.8.2 from source and writes the patched kext to `~/WhateverXe_nits.kext`.

## Install the built kext

1. Back up your current EFI folder.
2. Mount the EFI partition you actually boot from.
3. Replace `EFI/OC/Kexts/WhateverXe.kext` with the generated `~/WhateverXe_nits.kext`.
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

## Update: brightness on the OLED panel + Fn keys (K513EA, macOS 15.8.3)

### Why the slider did nothing with HDR off
The panel is an Intel HDR-TCON OLED. The PWM block is unused (`0xC8254` period = 0), and the standard eDP DPCD brightness register (`0x722`) is ignored. Brightness is set in nits at DPCD `0x354/0x355` (4-byte write, same as Linux i915), with `0x344` bit 4 set.

### Build the kext with the brightness patch (05)
```bash
bash build_whateverxe_edp_nits.sh      # -> ~/WhateverXe_nits.kext
```
Add the boot-arg `-wex-tgl-dpcd-bl`. Working boot-args:
```text
-v keepsyms=1 -allow3d -disablegfxfirmware -vi2c-force-polling -wexbeta -wex-tgl-edp-keep -wex-tgl-edp-softsleep -wex-tgl-dpcd-bl
```
Check: `ioreg -l -w0 | grep TGLDPCDBL` (the second block of `TGLDPCDBLDump` shows the nits value).

### Fn keys (ASUS EC queries)
- Fn+F4 / F5 = brightness down / up, Fn+F7 = keyboard backlight (off, 1, 2, 3, off).
- `python3 acpi/patch_dsdt_fn.py DSDT.aml` renames `_Q0C.._Q0F` to `XQ0C..XQ0F` in your own DSDT (writes `DSDT_fn.aml`, keep the original).
- Compile `acpi/SSDT-ASUS-FN.dsl` with `iasl`, put the `.aml` in `EFI/OC/ACPI/` and in `config.plist`.
- OpenCore `ACPI/Patch` rename entries did not apply on this board, hence the direct DSDT rename.
- Fn+F8/F9/F11 (Cmd+P, Cmd+L, Cmd+Shift+S) are sent by the keyboard itself; Fn+F6/F10/F12 have no macOS action.

### Other settings that helped
- `Misc/Debug/Target = 0`, `AppleDebug = false` and a restricted `Misc/Security/ScanPolicy` (`2622723` = APFS + ESP + NVMe + USB): OpenCore picker opens in ~1 s instead of ~30 s.
- GPU usage shows 0 % in monitoring apps (driver does not report counters); Metal / OpenCL still run on the GPU.
- HDR on: colours fade and max brightness drops (EDR on top of the panel nits). Keep HDR off.

