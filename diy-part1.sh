#!/bin/bash
set -e

# Argon 主题不走 feed：单包仓库根目录的 Makefile 不会被 feeds 安装。
# 在 diy-part2.sh 中直接 clone 到 package/luci-theme-argon。
# 这里保留给以后添加其他 feed 用。
true