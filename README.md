# PulseRelay Simulator

在 Windows 11 x64 上运行支持 Root、LSPosed 和实体蓝牙桥接的安卓模拟器，用于国内版小米运动健康与小米手环。

链路：Windows 蓝牙 → Google Bumble HCI 桥接 → Android Emulator → 小米运动健康 → PulseRelay 模块 → UDP 接收端。

## 使用预装包

从 [Releases](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases) 下载全部四个分卷、SHA256 文件和 `Join-Release.ps1`，放在同一文件夹，使用 PowerShell 运行合并脚本，再完整解压到 NTFS 磁盘。不要在压缩包内直接运行。

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
