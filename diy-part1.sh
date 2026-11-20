#!/bin/bash
set -e

# Argon 主题 v3：只添加主题仓库。
# 不要添加独立的 luci-app-argon-config，否则会和主题内置设置页冲突
# （APK 报 trying to overwrite ... owned by luci-theme-argon）。
sed -i '/^src-git argon/d' feeds.conf.default 2>/dev/null || true
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git;v3.1.4' >> feeds.conf.default