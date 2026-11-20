#!/bin/bash
set -e

# 应用 patches/ 下的可选补丁（相对 openwrt 源码根目录，-p1）。
shopt -s nullglob
for p in ../patches/*.patch; do
    echo "Applying patch: $p"
    patch -p1 < "$p"
done
shopt -u nullglob

# files/ 覆盖层由 workflow 复制到源码根目录，无需在此处理。
# 保证首次启动脚本有执行权限（git checkout 在 Windows 上可能丢 0755）。
chmod +x etc/uci-defaults/* 2>/dev/null || true

# 如果要改 Argon 主题本身，建议 fork 主题仓库并在 diy-part1.sh 中替换 feed URL。