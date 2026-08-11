#!/usr/bin/env bash
# ============================================================================
#  本地构建脚本（不走 GitHub Actions 也能用）
#  适用于：你直接在自己的 Mac 上编译，不想配置自托管 runner。
#  用法：
#    ./scripts/build_local.sh                        # 默认 M109 + iOS 12.0
#    ./scripts/build_local.sh 109.0.5414.119 12.0   # 指定版本 + iOS 最低版本
#  前置：Xcode（M109 建议 Xcode 14）、brew(install ninja gnu-sed python3)、可访问 googlesource 的网络。
# ============================================================================
set -euo pipefail

CHROMIUM_REF="${1:-109.0.5414.119}"
IOS_DEPLOYMENT_TARGET="${2:-12.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$HOME/chromium-ios-legacy-build"

export DEPOT_TOOLS_UPDATE=0
export PATH="$WORK/depot_tools:$PATH"

echo "==> 配置：Chromium=$CHROMIUM_REF  iOS>=$IOS_DEPLOYMENT_TARGET"
echo "==> 工作目录：$WORK"

mkdir -p "$WORK"
cd "$WORK"

# 1) depot_tools
if [ ! -d depot_tools ]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

# 2) 拉源码
if [ ! -d chromium/src ]; then
  mkdir -p chromium && cd chromium
  fetch --no-history ios
  cd "$WORK"
fi

# 3) 切版本 + 同步依赖
cd "$WORK/chromium/src"
git fetch --tags origin
git checkout "$CHROMIUM_REF"
gclient sync -D --with_branch_heads

# 4) 应用补丁
bash "$ROOT/config/apply_patches.sh" "$ROOT/patches"

# 5) gn 配置
mkdir -p out/Release-iphoneos
CONFIG_ARGS="$ROOT/config/args.gn" IOS_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET" \
python3 - <<'PY'
import os
t = open(os.environ["CONFIG_ARGS"]).read()
t = t.replace("__IOS_DEPLOYMENT_TARGET__", os.environ["IOS_DEPLOYMENT_TARGET"])
with open("out/Release-iphoneos/args.gn", "w") as f:
    f.write(t)
print("args.gn 写入完成，ios_deployment_target =", os.environ["IOS_DEPLOYMENT_TARGET"])
PY
gn gen out/Release-iphoneos

# 6) 编译
autoninja -C out/Release-iphoneos chrome

# 7) 打包 IPA（未签名）
cd out/Release-iphoneos
rm -rf Payload
mkdir -p Payload
mv Chromium.app Payload/
IPA="$HOME/Chromium-${CHROMIUM_REF}-ios${IOS_DEPLOYMENT_TARGET}.ipa"
rm -f "$IPA"
zip -r -y "$IPA" Payload
echo "==> 完成！IPA: $IPA"
