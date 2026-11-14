#!/usr/bin/env bash
# Build WhateverXe 0.8.2 with the Tiger Lake eDP keep/softsleep and RedmiBook
# BPC/backlight patches. Tested by the repository maintainer on ASUS K513EA.
set -Eeuo pipefail

readonly WORK_DIR="${HOME}/wex-build"
readonly WEX_DIR="${WORK_DIR}/WhateverXe"
readonly SDK_DIR="${WORK_DIR}/MacKernelSDK"
readonly LILU_DIR="${WORK_DIR}/Lilu"
readonly PATCH_BASE="https://raw.githubusercontent.com/WilliamAlexanda/macOS-for-RedmiBook-Pro-15-2021/main/patches/whateverxe-0.8.0"
readonly OUTPUT_DIR="${WEX_DIR}/build/RELEASE"
readonly FINAL_KEXT="${HOME}/WhateverXe_bpc.kext"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || die "git is required."
command -v curl >/dev/null 2>&1 || die "curl is required."
command -v python3 >/dev/null 2>&1 || die "python3 is required."
xcode-select -p >/dev/null 2>&1 || die "Xcode Command Line Tools are missing. Run: xcode-select --install"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "[1/6] Preparing pinned source repositories..."
if [[ ! -d "$WEX_DIR/.git" ]]; then
  git clone -q --branch 0.8.2 --depth 1 https://github.com/b00t0x/WhateverXe.git "$WEX_DIR"
else
  git -C "$WEX_DIR" fetch -q --tags
  git -C "$WEX_DIR" checkout -q 0.8.2
  git -C "$WEX_DIR" reset --hard -q 0.8.2
  git -C "$WEX_DIR" clean -fdq
fi

if [[ ! -d "$SDK_DIR/.git" ]]; then
  git clone -q https://github.com/acidanthera/MacKernelSDK.git "$SDK_DIR"
fi
git -C "$SDK_DIR" checkout -q 05094e5e88cec7caedbfb35e8449ed0db94bf95b

if [[ ! -d "$LILU_DIR/.git" ]]; then
  git clone -q --branch 1.7.2 --depth 1 https://github.com/acidanthera/Lilu.git "$LILU_DIR"
else
  git -C "$LILU_DIR" fetch -q --tags
  git -C "$LILU_DIR" checkout -q 1.7.2
fi

echo "[2/6] Downloading community patches..."
for patch in \
  02-tgl-edp-keep-softsleep.patch \
  03-redmibook-bpc-backlight.patch
do
  curl --fail --location --silent --show-error \
    "${PATCH_BASE}/${patch}" \
    --output "${WORK_DIR}/${patch}" \
    || die "Could not download ${patch}. Check the upstream patch URL."
done

echo "[3/6] Verifying and applying patches..."
cd "$WEX_DIR"
for patch in \
  02-tgl-edp-keep-softsleep.patch \
  03-redmibook-bpc-backlight.patch
do
  git apply --check "${WORK_DIR}/${patch}" \
    || die "${patch} does not apply cleanly to WhateverXe 0.8.2. No build was produced."
  git apply "${WORK_DIR}/${patch}"
done

echo "[4/6] Linking build dependencies..."
ln -sfn "$SDK_DIR" "${WEX_DIR}/MacKernelSDK"
mkdir -p "${WEX_DIR}/Lilu.kext/Contents/Resources"
ln -sfn "${LILU_DIR}/Lilu/Headers" "${WEX_DIR}/Lilu.kext/Contents/Resources/Headers"
ln -sfn "${LILU_DIR}/Lilu/Library" "${WEX_DIR}/Lilu.kext/Contents/Resources/Library"

echo "[5/6] Building release kext..."
python3 tools/build.py --release --output build/RELEASE

[[ -d "${OUTPUT_DIR}/WhateverXe.kext" ]] || die "Build completed but WhateverXe.kext was not found at ${OUTPUT_DIR}."

echo "[6/6] Copying result..."
rm -rf "$FINAL_KEXT"
ditto "${OUTPUT_DIR}/WhateverXe.kext" "$FINAL_KEXT"

echo
echo "BUILD SUCCESSFUL"
echo "Patched kext: ${FINAL_KEXT}"
echo
echo "Next: back up your EFI, replace EFI/OC/Kexts/WhateverXe.kext,"
echo "verify your OpenCore config, reset NVRAM, and reboot."
echo "This script does not modify your EFI automatically."
