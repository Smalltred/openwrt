# CR8809 自定义 OpenWrt 构建仓库

目标设备：**小米 CR8809 A 版**（DTS config `mp02.1`，兼容 Redmi AX3000 / CR880x）。

- 源码：`hzyitc/openwrt-redmi-ax3000`，分支 `ipq50xx-mainline-kernel-5.15-openwrt-23.05`
- 系统：OpenWrt 23.05，内核 5.15，armv7
- UI：Argon v3.1.4（主题内置设置页）+ 中文 + 常用工具
- 产物：`openwrt-ipq50xx-arm-redmi_ax3000-squashfs-nand-factory.ubi`

> 说明：CR8809 目前没有可用的 6.18 内核固件。flippy 的 `s905d_n1` 镜像是斐讯 N1 电视盒子的整盘镜像，**不能**用于这台路由器。

## 目录结构

```
.
├── .github/workflows/build.yml   # GitHub Actions 编译流程
├── configs/redmi_ax3000.config   # 设备 + 软件包配置
├── files/                        # 打包进固件的覆盖文件
│   └── etc/
│       ├── banner
│       └── uci-defaults/99-cr8809-custom
├── patches/                      # 可选源码补丁（*.patch，-p1）
├── diy-part1.sh                  # 添加 Argon feed
└── diy-part2.sh                  # 应用补丁、修正权限
```

## 快速开始

1. 在 GitHub 新建仓库（本仓库已创建：`Smalltred/openwrt`）。
2. 把本目录全部文件推到仓库根目录（包括 `.github`）。
3. 打开 **Actions → Build CR8809 OpenWrt → Run workflow**。
4. 首次编译约 **40–90 分钟**；之后有 ccache 会快一些。
5. 在运行结果页下载 artifact **`cr8809-openwrt`**，里面是 `.ubi` 固件。

推送命令：

```bash
cd build
git init
git add .
git commit -m "Initial CR8809 OpenWrt build workflow"
git branch -M master
git remote add origin https://github.com/Smalltred/openwrt.git
git push -u origin master
```

## 自定义

### 改软件包 / UI

编辑 `configs/redmi_ax3000.config`：

```ini
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-commands=y
# 想加的包直接追加
```

> Argon v3 的设置页已经内置在主题里，**不要**再加 `luci-app-argon-config`，否则会文件冲突。

### 改首次启动默认值

编辑 `files/etc/uci-defaults/99-cr8809-custom`，例如改主机名、时区、默认语言、默认主题。

### 改 Argon 主题本身

建议 fork `jerrykuku/luci-theme-argon`，把 `diy-part1.sh` 里的 feed URL 换成你的 fork（并固定 tag/commit），
这样每次云端编译都会用你的修改。

### 给源码打补丁

把 `*.patch` 放进 `patches/`，`diy-part2.sh` 会按 `-p1` 依次应用。

## 刷机（前提）

本仓库只负责**编译**。刷机前需要：

1. 已通过 `xmir-patcher` 解锁 SSH（CR8809 A 版可行）。
2. 已备份全部分区（boot / rootfs / overlay / data）。
3. 已写入带 Web 恢复的 U-Boot（`MIBIB.bin`、`APPSBL.bin`、`APPSBL1.bin`）。

刷写步骤：

1. 路由器断电，按住 Reset，上电保持 10 秒后松开。
2. 电脑访问 <http://192.168.10.1/uboot.html>（用 Chrome，不要用 Firefox）。
3. 上传编译出的 `.ubi`。
4. 重启后 OpenWrt 默认地址为 `192.168.1.1`。

> 写入 U-Boot 是不可逆步骤；没有备份和恢复手段时不要操作。

## 常见问题

- **Argon 编译失败**：把 `diy-part1.sh` 的 tag 改成 `v3.0.0` 或 `v3.1.0` 再试。
- **某个软件包不存在**：从 `.config` 删掉该包，`make defconfig` 会忽略未知符号。
- **编译超时 / 磁盘不足**：workflow 已包含清理 runner 磁盘的步骤；若仍不足，减少软件包。
- **没有生成 `.ubi`**：检查 `configs/redmi_ax3000.config` 里的 `CONFIG_TARGET_ipq50xx_arm_DEVICE_redmi_ax3000=y`。

## 安全

刷机后 root 默认无密码、SSH 默认关闭。请先在 LuCI 设置管理员密码，再按需开启 SSH。