#!/bin/bash
set -e

# Argon 主题：直接放入 package/（官方推荐做法）。
# v3 的设置页已内置，不要再添加独立的 luci-app-argon-config。
rm -rf package/luci-theme-argon
git clone --depth 1 --branch v3.1.4 \
    https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# 应用 patches/ 下的可选补丁（相对 openwrt 源码根目录，-p1）。
shopt -s nullglob
for p in ../patches/*.patch; do
    echo "Applying patch: $p"
    patch -p1 < "$p"
done
shopt -u nullglob

# files/ 覆盖层由 workflow 复制到 openwrt/files/。
# 保证首次启动脚本有执行权限（checkout/Windows 可能丢 0755）。
chmod +x files/etc/uci-defaults/* 2>/dev/null || true

# 如果要改 Argon 主题本身，直接改 package/luci-theme-argon，或把它换成你的 fork。