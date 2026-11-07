# PulseRelay Simulator

在 Windows 11 x64 上运行支持 Root、LSPosed 和实体蓝牙桥接的安卓模拟器，用于国内版小米运动健康与小米手环。

链路：Windows 蓝牙 → Google Bumble HCI 桥接 → Android Emulator → 小米运动健康 → PulseRelay 模块 → UDP 接收端。

## 轻量在线安装版

从 Releases 下载 `PulseRelay-OnlineInstaller-v0.2.1.zip`，约 5.3 MiB，随包带 Zadig 与 AEHD。先运行 `Configure-Download-Proxy.cmd` 配置下载代理，再运行 `Install.cmd`。

安装器首次下载约 3.66 GiB 的已验证 v0.1.2 运行环境，校验全部分卷与整包后安装到新目录，保留预装的 Root、LSPosed 和 PulseRelay 作用域。默认语言为简体中文、地区为中国、时区为 Asia/Shanghai。支持 HTTP/SOCKS5 代理、缓存续传；不会覆盖已有安卓数据。下载代理与安卓应用代理分别配置。详细说明见 [在线安装器说明](installer/README.md)。

源码中的 `installer/` 不提交工具二进制。维护者使用 `scripts/build_online_installer.py --resources-source <现有预装目录> --output <新ZIP路径>` 生成轻量包；完整预装包仍可用于离线安装。

## 使用预装包

从 [Releases](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases) 下载同一版本的全部分卷、SHA256 文件和 `Join-Release.ps1`，放在同一文件夹，使用 PowerShell 运行合并脚本，再完整解压到 NTFS 磁盘。不要在压缩包内直接运行。

1. 电脑需为 Intel/AMD x64，BIOS 已开启 CPU 虚拟化；Windows ARM 未验证。
2. 运行 `First-Run-Drivers.cmd` 检查/安装加速驱动。使用 Hyper-V 的电脑应启用 Windows Hypervisor Platform，按提示重启。
3. 运行 `Configure-Bluetooth.cmd` 选择专供安卓使用的适配器，在 Zadig 中核对 VID/PID 后切换为 WinUSB。Windows 会失去该适配器的使用权，请准备有线键鼠。
4. 运行 `Start-PulseRelay.cmd`，在 LSPosed 中确认 PulseRelay 已启用，作用域为 `com.mi.health`。
5. 在小米运动健康内自行登录、绑定手环。退出使用 `Stop-PulseRelay.cmd`，等窗口完全关闭再移动文件夹。

详细操作与恢复 Windows 蓝牙的方法见 [迁移包说明](PORTABLE-README.md)。Intel AX211 已实测，其他适配器取决于固件、驱动与 WinUSB 支持，不能保证兼容。

## 组件与验证

| 组件 | 版本 |
| --- | --- |
| Android | 12 / API 31 Google APIs x86_64，支持 ARM64 转译 |
| Emulator | 37.1.11 |
| Magisk | 25.2 |
| LSPosed | 1.9.2 / Zygisk |
| 国内版小米运动健康 | 3.59.2 / `com.mi.health` |
| PulseRelay | 3.1.0 发布 APK；内部版本标记为 3.0.1（301） |
| Bumble | 0.0.236 |

预装包采用全新安卓数据，确认系统账号数量为 0，不带原模拟器账号、手环绑定或宿主机 ADB 私钥。已验证含空格目录迁移启动、Root、LSPosed、PulseRelay 7 个心率 Hook 加载及安卓内真实 BLE 扫描。Hook 加载不代表手环已绑定或 OBS 已收到心率；其他电脑仍需首次配置驱动。

模块设置入口：小米运动健康 → 我的 → 关于，长按图标。若 OBS 在同一台 Windows 上运行，UDP 接收目标可填写 `10.0.2.2:18181`。本项目未安装 OBS 插件。

## 源码与配置

源码仓库仅提交脚本、诊断应用源码、配置示例及文档。磁盘镜像、下载资源、APK、日志、驱动备份、个人配置和大型压缩包均不进入 Git。

复制 `config.example.json` 为 `config.json`，按实际情况设置路径和端口。预装包独立包含 Android Emulator、Python、Bumble 与系统镜像；仅克隆源码不会自动下载这些资源。下载来源与许可见 [THIRD-PARTY.md](THIRD-PARTY.md)。

默认代理为 `http://127.0.0.1:7897`，SOCKS 为 `socks5://127.0.0.1:7897`。安卓应用通过 `10.0.2.2:7897` 使用宿主机代理；本机 gRPC 与 ADB 不走代理。新电脑需提供对应代理或修改配置。

- `scripts/Start-PulseRelay.ps1`、`Stop-PulseRelay.ps1`：启动与关闭。
- `scripts/bluetooth_bridge.py`：USB HCI/netsim 桥接，包含 Intel 固件引导和重枚举处理。
- `scripts/Configure-Bluetooth.ps1`：记录设备、备份原驱动并打开 Zadig。
- `scripts/Install-Root.ps1`、`Install-AndroidApps.ps1`：维护工具，需预备对应下载资源，日常无需运行。
- `diagnostics/`：BLE 诊断应用，构建另需 JDK、build-tools 36 和 API 34。
- `scripts/stage_portable.py`、`archive_portable.py`：维护者打包工具，仅处理 `dist` 下新建的干净实例；打包前必须停止实例。

不要从已登录的个人实例直接制作公开包。发布包经过完整 ZIP CRC 与 SHA256 校验。

## 上游

- [PulseRelay 模块](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay)
- [OBS 接收插件](https://github.com/ChlorophyTeio/heart-rate-obs-plugin)
- [Bumble](https://google.github.io/bumble/platforms/android.html)
- [LSPosed](https://github.com/LSPosed/LSPosed)
- [rootAVD](https://gitlab.com/newbit/rootAVD)

## Windows 蓝牙恢复与启动修复

双击 `Restore-WindowsBluetooth.cmd`，允许管理员权限提示。脚本会停止本包的模拟器/蓝牙桥接，再恢复所选适配器的 Windows 驱动。

对于 `USB\VID_13D3&PID_3617`（Realtek RTL8922AE），首次恢复会从华硕官网下载约 3 MB 的专用驱动，并验证官方 SHA256；不会仅凭通用驱动显示正常就判定无线扫描正常。其他适配器使用匹配的原厂驱动备份；备份缺失时会提示安装主板厂商驱动。切回 Windows 后，该适配器不能同时供安卓桥接使用。

此修复还将桥接启动等待延长至 120 秒、增加启动阶段日志，并修复 Windows PowerShell 5.1 在安卓启动期间遇到 `device offline` 直接退出的问题。Realtek 专用驱动已在 ROG STRIX B850-G GAMING WIFI S 上成功安装，设备无错误；附近设备发现和实际配对仍需用户验证，不能据此宣称其他适配器兼容。


## v0.1.2 Realtek 固件修复与完整包

启动桥接时为 Realtek RTL8922AE（13D3:3617）加载并校验易失性补丁固件。此前仅开启 HCI/蓝牙状态不足以让无线扫描工作；本版已验证宿主机扫描及安卓配对页面发现附近 BLE 设备。具体小米手环的发现、登录、绑定与心率发送仍需用户验证。退出时等待 QEMU 完全关闭后再停止桥接，避免提前断开传输。

完整包从全新安卓数据盘重新预装，包含 Realtek 固件和 Windows 恢复驱动缓存；无账号、配对记录和 ADB 主机私钥。源码克隆首次启动会自动下载并校验 Realtek 固件。
