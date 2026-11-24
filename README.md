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
│   ├── etc/
│   │   ├── banner
│   │   ├── init.d/dns-failover               # DNS 降级守护（procd 常驻）
│   │   ├── sysctl.d/99-bypass.conf           # 关 ICMP 重定向 + BBR
│   │   └── uci-defaults/99-cr8809-custom     # 首次启动：旁路由 + DNS + 待命 DHCP
│   └── usr/bin/dns-failover.sh
├── patches/                      # 可选源码补丁（*.patch，-p1）
├── diy-part1.sh                  # 预留（当前为空）
└── diy-part2.sh                  # clone Argon、应用补丁、修正权限
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
CONFIG_PACKAGE_htop=y
# 想加的包直接追加
```

中文界面必须保留：

```ini
CONFIG_LUCI_LANG_zh_Hans=y
```

> Argon v3 的设置页已经内置在主题里，**不要**再加 `luci-app-argon-config`，否则会文件冲突。

### 改首次启动默认值

编辑 `files/etc/uci-defaults/99-cr8809-custom`，例如改主机名、时区、默认语言、默认主题。

### 改 Argon 主题本身

Argon 不走 feed，而是在 `diy-part2.sh` 里直接 clone 到 `package/luci-theme-argon`。
要改主题就 fork `jerrykuku/luci-theme-argon`，把 `diy-part2.sh` 里的 clone URL 换成你的 fork，
并固定 tag/commit，这样每次云端编译都会用你的修改。

> 单包仓库的根目录 Makefile 不会被 `feeds install` 识别，所以不要把它做成 feed。

### 给源码打补丁

把 `*.patch` 放进 `patches/`，`diy-part2.sh` 会按 `-p1` 依次应用。

## 内置软件包

本固件定位为**有线单臂旁路由**：只负责 DNS 与转发，代理由 PVE 上的 mihomo 提供。
因此镜像只保留运行所需的最小集合：

| 类别 | 包 |
| --- | --- |
| 系统 | `dnsmasq-full`、`firewall4`（默认）、`dropbear`（默认） |
| UI | `luci`、`luci-mod-admin-full`、`luci-app-firewall`、`luci-app-opkg`、`luci-theme-argon` |
| 中文 | `luci-i18n-base-zh-cn`、`luci-i18n-firewall-zh-cn`、`luci-i18n-opkg-zh-cn` |
| 转发 | `kmod-nft-offload`、`kmod-tcp-bbr` |
| 工具 | `ca-bundle`、`wget-ssl`、`zoneinfo-asia` |
| 无线 | `ath11k-firmware-ipq5018`、`kmod-ath11k`、`wpad-basic-wolfssl`（默认关闭射频） |

> **体积硬约束**：U-Boot Web 恢复实测上限约 **14 MiB**（14.38 MiB 的镜像被拒，
> 资源包内可用的两个镜像是 11.00 / 14.00 MiB）。因此使用 1 MB squashfs 块提高
> xz 压缩率，并裁掉 `htop`/`nano`/`curl`/`ppp` 等非必需包。

**有意不打包**（相对上一版减少约 65 MB 未压缩体积）：

| 已移除 | 原体积 | 原因 |
| --- | --- | --- |
| `xray-core` | 24.7 MB | 代理在 PVE |
| `luci-app-openclash` | 22.1 MB | 代理在 PVE |
| `lucky` + `luci-app-lucky` | 13.5 MB | 未使用 |
| `luci-app-passwall` + 5 个辅助包 | ~5 MB | 未使用 |
| `luci-app-oaf` + `appfilter` + `kmod-oaf` | ~2.1 MB | 未使用 |
| `luci-app-adguardhome` | ~0.5 MB | 未使用 |
| `luci-theme-aurora` / `bootstrap` | ~1 MB | 只保留 Argon |
| `luci-app-ttyd` / `commands` / `upnp` / `ddns` / `sqm` / `wol` | ~1 MB | SSH 可替代，旁路由不需要 |
| `htop` / `nano` / `curl` / `ppp` / `pppoe` | ~1 MB | 控制体积；PPPoE 由中兴主路由承担 |

需要重新加回代理时，在 `configs/redmi_ax3000.config` 追加对应 `CONFIG_PACKAGE_*`，
并在 `diy-part2.sh` 恢复相应的 clone 与 `cp` 步骤（旧版可从 git 历史 `a2ad269` 取回）。

**未包含**：`daede`。它的 2026 源码要求 Go 1.24，而本源码树是 Go 1.21.7，
编译必失败；后续可换预编译二进制或升级 Go 工具链再加。

> 体积提醒：合并大分区后可用约 88 MB。workflow 会打印 `.ubi` 大小。

## 刷机（前提）

本仓库只负责**编译**。刷机前需要：

1. 已通过 `xmir-patcher` 解锁 SSH（CR8809 A 版可行）。
2. 已备份全部分区（boot / rootfs / overlay / data）。
3. 已写入带 Web 恢复的 U-Boot（`MIBIB.bin`、`APPSBL.bin`、`APPSBL1.bin`）。

刷写步骤：

1. 路由器断电，按住 Reset，上电保持 10 秒后松开。
2. 电脑访问 <http://192.168.10.1/uboot.html>（用 Chrome，不要用 Firefox）。
3. 上传编译出的 `.ubi`。
4. 重启后 OpenWrt 默认地址为 **`192.168.2.20`**（首次启动的 uci-defaults 已按单臂旁路由配置好）。

> 写入 U-Boot 是不可逆步骤；没有备份和恢复手段时不要操作。

## 常见问题

- **Argon 编译失败**：把 `diy-part2.sh` 里的 `--branch v3.1.4` 改成 `v3.0.0` 或 `v3.1.0` 再试。
- **中文没生效**：确认 `.config` 里有 `CONFIG_LUCI_LANG_zh_Hans=y`。
- **自定义文件没进固件**：`files/` 必须落到源码的 `openwrt/files/`，workflow 已按此复制。
- **旁路由不生效**：确认 uci-defaults 已执行（`uci get network.lan.ipaddr` 应为 `192.168.2.20`），
  且 `sysctl net.ipv4.conf.all.send_redirects` 为 `0`；否则客户端会绕过本机直连 PVE。
- **降级没触发**：看 `cat /tmp/dns-failover.state` 和 `/root/dns-failover.log`，
  确认 `/etc/init.d/dns-failover` 已 enable、`nslookup www.baidu.com 192.168.2.7` 有响应。
- **镜像太大**：本配置已移除全部代理组件；若再加包，优先检查 OpenClash 与其核心体积。
- **某个软件包不存在**：从 `.config` 删掉该包，`make defconfig` 会忽略未知符号。
- **编译超时 / 磁盘不足**：workflow 已包含清理 runner 磁盘的步骤；若仍不足，减少软件包。
- **没有生成 `.ubi`**：检查 `configs/redmi_ax3000.config` 里的 `CONFIG_TARGET_ipq50xx_arm_DEVICE_redmi_ax3000=y`。

## 安全

刷机后 root 默认无密码、SSH 默认关闭。请先在 LuCI 设置管理员密码，再按需开启 SSH。