#!/usr/bin/env bash
# ============================================================================
#  应用 patches/ 下的所有 *.patch 到 chromium/src
#  设计原则：补丁是“尽力而为”——若某补丁已被上游包含或上下文不匹配，
#  打印警告后继续，不阻断整体构建（因为不同 Chromium ref 需要的补丁不同）。
#  用法： apply_patches.sh <patches目录>
# ============================================================================
set -u

PATCH_DIR="${1:-patches}"
if [ ! -d "$PATCH_DIR" ]; then
  echo "[apply_patches] 未找到补丁目录 $PATCH_DIR，跳过。"
  exit 0
fi

shopt -s nullglob
patches=("$PATCH_DIR"/*.patch)
if [ ${#patches[@]} -eq 0 ]; then
  echo "[apply_patches] 没有 .patch 文件，跳过（如需 iOS10 兼容补丁，请把补丁放到 $PATCH_DIR）。"
  exit 0
fi

echo "[apply_patches] 共发现 ${#patches[@]} 个补丁。"
for p in "${patches[@]}"; do
  echo "== 应用 $(basename "$p") =="
  # --3way 在上下文不完全匹配时尝试三方合并
  if git apply --ignore-whitespace --3way "$p" 2>/dev/null; then
    echo "   已应用。"
  else
    echo "   WARN: 未能应用（可能已包含或冲突），跳过继续。"
  fi
done
echo "[apply_patches] 完成。"
