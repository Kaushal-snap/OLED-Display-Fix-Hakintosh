#!/bin/bash
# WhateverXe 0.8.2 + 02 (eDP keep) + 03 (bpc) + 05 (OLED AUX/nits backlight) -> ~/WhateverXe_nits.kext
set -euo pipefail
W="$HOME/wex-build"; mkdir -p "$W" && cd "$W"
[ -d WhateverXe ] || git clone -q --branch 0.8.2 --depth 1 https://github.com/b00t0x/WhateverXe.git
[ -d MacKernelSDK ] || { git clone -q https://github.com/acidanthera/MacKernelSDK.git && git -C MacKernelSDK checkout -q 05094e5e88cec7caedbfb35e8449ed0db94bf95b; }
[ -d Lilu ] || git clone -q --branch 1.7.2 --depth 1 https://github.com/acidanthera/Lilu.git
cd WhateverXe; git checkout -q -- .
R=https://raw.githubusercontent.com/WilliamAlexanda/macOS-for-RedmiBook-Pro-15-2021/main/patches/whateverxe-0.8.0
M=https://raw.githubusercontent.com/Kaushal-snap/OLED-Display-Fix-Hakintosh/main/patches
for P in "$R/02-tgl-edp-keep-softsleep.patch" "$R/03-redmibook-bpc-backlight.patch" "$M/05-tgl-dpcd-backlight.patch"; do
  F="../$(basename "$P")"; curl -fsSL -o "$F" "$P"; git apply --check "$F"; git apply "$F"
done
ln -sfn ../MacKernelSDK MacKernelSDK
mkdir -p Lilu.kext/Contents/Resources
ln -sfn "$W/Lilu/Lilu/Headers" Lilu.kext/Contents/Resources/Headers
ln -sfn "$W/Lilu/Lilu/Library" Lilu.kext/Contents/Resources/Library
python3 tools/build.py --release --output build/RELEASE 2>&1 | tail -5
rm -rf "$HOME/WhateverXe_nits.kext"; cp -R build/RELEASE/WhateverXe.kext "$HOME/WhateverXe_nits.kext"
echo "BUILD OK: $HOME/WhateverXe_nits.kext"
