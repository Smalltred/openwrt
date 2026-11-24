#!/bin/bash
set -e

# 本固件定位为有线单臂旁路由（DNS + 转发），代理由 PVE 上的 mihomo 提供。
# 因此不再拉取 OpenClash / PassWall / Lucky / OAF / AdGuardHome / TurboACC，
# 只需 Argon 主题（单包仓库，不走 feed）。

# Argon 主题：clone 到 package/luci-theme-argon
rm -rf package/luci-theme-argon
git clone --depth 1 --branch v3.1.4 \
    https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
rm -rf package/luci-theme-argon/.git

# 应用 patches/ 下的可选补丁（-p1）
shopt -s nullglob
for p in ../patches/*.patch; do
    echo "Applying patch: $p"
    patch -p1 < "$p"
done
shopt -u nullglob

# files/ 覆盖层由 workflow 复制到 openwrt/files/，确保可执行位正确
chmod +x files/etc/uci-defaults/* 2>/dev/null || true
chmod +x files/etc/init.d/* 2>/dev/null || true
chmod +x files/usr/bin/* 2>/dev/null || true
