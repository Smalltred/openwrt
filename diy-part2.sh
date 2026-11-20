#!/bin/bash
set -e

PLUG=/tmp/owrt-plugins
rm -rf "$PLUG"
mkdir -p "$PLUG"

clone() {
    echo "==> clone $2"
    git clone --depth 1 "$1" "$PLUG/$2"
    rm -rf "$PLUG/$2/.git"
}

# 第三方 LuCI 应用 / 主题
clone https://github.com/kongfl888/luci-app-adguardhome.git adguardhome
clone https://github.com/eamonxg/luci-theme-aurora.git aurora
clone https://github.com/gdy666/luci-app-lucky.git lucky
clone https://github.com/destan19/OpenAppFilter.git oaf
clone https://github.com/Openwrt-Passwall/openwrt-passwall.git passwall
clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git passwall-packages
clone https://github.com/vernesong/OpenClash.git openclash
clone https://github.com/chenmozhijin/turboacc.git turboacc

# 复制到构建树（目录名决定包名）
cp -r "$PLUG/adguardhome" package/luci-app-adguardhome
cp -r "$PLUG/aurora" package/luci-theme-aurora
cp -r "$PLUG/lucky/luci-app-lucky" package/
cp -r "$PLUG/lucky/lucky" package/
cp -r "$PLUG/oaf/luci-app-oaf" package/
cp -r "$PLUG/oaf/oaf" package/
cp -r "$PLUG/oaf/open-app-filter" package/appfilter
cp -r "$PLUG/passwall/luci-app-passwall" package/
cp -r "$PLUG/openclash/luci-app-openclash" package/

# U-Boot Web 上传受 36 MB fs 分区限制；去掉 OpenClash 可选大数据，
# 这些文件可在 OpenWrt 启动后通过 OpenClash 的 GeoData/UI 下载。
rm -rf package/luci-app-openclash/root/usr/share/openclash/ui
rm -f package/luci-app-openclash/root/etc/openclash/GeoSite.dat
rm -f package/luci-app-openclash/root/etc/openclash/Country.mmdb
rm -rf package/luci-app-openclash/root/etc/openclash/rule_provider
cp -r "$PLUG/turboacc/luci-app-turboacc" package/

# Passwall 依赖的辅助包 + Xray 核心
for p in chinadns-ng dns2socks ipt2socks microsocks tcping xray-core; do
    cp -r "$PLUG/passwall-packages/$p" package/
done

# Xray 2026 源码要求 Go 1.24，而本源码树是 Go 1.21.7。
# 固定到 v1.8.24（go.mod: go 1.21.4），Passwall 26.x 仍可使用。
sed -i 's/^PKG_VERSION:=.*/PKG_VERSION:=1.8.24/' package/xray-core/Makefile
sed -i 's/^PKG_HASH:=.*/PKG_HASH:=86e3e388c77cda4d8457a607356416c201c1f18bbed53f0a9e76a228508ff298/' package/xray-core/Makefile

# Argon 主题（与 Aurora 共存，默认仍由 99-cr8809-custom 设为 Argon）
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

# files/ 覆盖层由 workflow 复制到 openwrt/files/
chmod +x files/etc/uci-defaults/* 2>/dev/null || true