# PulseRelay Simulator

在 Windows 11 x64 上运行带 Root、LSPosed 和实体蓝牙桥接的 Android 12 模拟器，用于国内版小米运动健康与 PulseRelay 心率转发。

数据链路：实体蓝牙适配器（WinUSB）→ Bumble HCI 桥接 → Android Emulator → 小米运动健康 → PulseRelay → UDP 接收端。

## 下载与版本选择

| 方式 | 下载 | 体积 | 适用情况 |
| --- | --- | --- | --- |
| 轻量在线安装器 v0.2.1 | [下载安装器 ZIP](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases/download/v0.2.1/PulseRelay-OnlineInstaller-v0.2.1.zip) · [SHA256](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases/download/v0.2.1/PulseRelay-OnlineInstaller-v0.2.1.zip.sha256) | 约 5.28 MiB | 新用户，首次安装时可以联网 |
| 完整包更新补丁 v0.2.1 | [下载补丁 ZIP](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases/download/v0.2.1/PulseRelay-FullPackage-Update-v0.2.1.zip) · [SHA256](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases/download/v0.2.1/PulseRelay-FullPackage-Update-v0.2.1.zip.sha256) | 约 5.6 KB | 已有完整 v0.1.2 包或在线安装后的运行目录 |
| 完整离线包 v0.1.2 | [下载全部分卷](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases/tag/v0.1.2) | 合计约 3.66 GiB | 需要离线安装或迁移到其他电脑 |

[查看所有发布](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases)。安装器和补丁版本为 v0.2.1，底层预装运行环境仍为 v0.1.2；无需寻找“v0.2.1 完整镜像”。

在线安装器缩小的是首次取得的安装文件，**首次仍需下载约 3.66 GiB**，最终运行环境的磁盘占用不会因此减少。建议预留 **30 GB** 空间。

## 新用户：在线安装

1. 下载并完整解压在线安装器，不要在 ZIP 内直接运行。包内已带 Zadig 2.9 和 AEHD 2.2 加速驱动。
2. 需要下载代理时，先运行 `Configure-Download-Proxy.cmd`，修改并保存 `download-settings.json`；默认直连。
3. 双击 `Install.cmd`。安装器会下载固定版本的运行环境，校验全部分卷及整包 SHA256，再安装到本目录下的 `PulseRelay` 文件夹。
4. 进入安装后的 `PulseRelay` 文件夹，按下方“首次启动与日常使用”配置加速和蓝牙。

支持缓存续传、重试和跳过已校验的下载。安装到已有目录时不会覆盖安卓数据；对同一在线安装目录再次运行 v0.2.1 安装器，会更新对应启动脚本。自定义路径、仅下载模式等说明见 [在线安装器说明](installer/README.md)。

### 下载代理

双击 `Configure-Download-Proxy.cmd` 后，按需设置：

HTTP 代理：

```json
{
  "downloadProxyMode": "custom",
  "downloadProxyUrl": "http://127.0.0.1:7897"
}
```

SOCKS5 代理（通过代理解析域名）：

```json
{
  "downloadProxyMode": "custom",
  "downloadProxyUrl": "socks5h://127.0.0.1:7897"
}
```

直连时将 `downloadProxyMode` 设为 `direct`。设为 `environment` 时使用 `HTTPS_PROXY`、`HTTP_PROXY` 等环境变量，不会自动读取 Windows 系统代理。

这些设置只控制安装器下载。安卓应用默认通过 `10.0.2.2:7897` 使用宿主机代理，与下载代理独立；下载代理的修改不会自动同步到安卓内。

## 已有完整包：应用更新补丁

v0.2.1 补丁为已有完整 v0.1.2 包添加以下默认设置：

- 语言：简体中文（`zh-CN`）。
- 国家/地区：中国。
- 时区：上海（`Asia/Shanghai`，UTC+8），关闭自动时区。

更新步骤：

1. 在原目录运行 `Stop-PulseRelay.cmd`，等待模拟器完全退出。
2. 将补丁 ZIP 解压到一个新文件夹，运行 `Apply-FullPackage-Update.cmd`。
3. 输入原安装目录，即同时包含 `config.json`、`scripts`、`runtime` 的目录。
4. 提示 `Updated` 后，用原 `Start-PulseRelay.cmd` 启动。首次切换语言时安卓会自动重启一次。

补丁只备份并替换 `Start-PulseRelay.ps1`、`Set-AndroidDefaults.ps1`，不修改 `config.json`、蓝牙适配器选择、账号、配对记录和安卓数据盘。旧脚本位于原目录的 `updates/backups/` 下。适用范围及回退方法见 [完整包补丁说明](patches/full-package/README.md)。

新版在线安装器已包含这项更新，无需再应用补丁。

## 离线安装完整包

从 [v0.1.2 发布页](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator/releases/tag/v0.1.2) 下载以下文件，放在同一目录：

- 全部 4 个分卷：`PulseRelay-Windows-Clean.zip.part001` 至 `part004`。
- `PulseRelay-Windows-Clean.zip.sha256`。
- `Join-Release.ps1`。

运行合并与校验：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Join-Release.ps1
```

校验成功后，会在同目录生成完整的 `PulseRelay-Windows-Clean.zip`。将它完整解压到 NTFS 磁盘，再应用上方 v0.2.1 补丁，即可使用简体中文、中国地区和上海时区默认设置。不要混用不同版本的分卷。

## 首次启动与日常使用

适用于 Windows 11 x64、Intel/AMD CPU，BIOS 需开启硬件虚拟化；Windows ARM 不支持。CPU 厂商与蓝牙芯片厂商可能不同，蓝牙兼容性取决于具体适配器及其固件。

1. 运行 `First-Run-Drivers.cmd` 检查/安装加速驱动。若使用 Hyper-V，请启用 Windows Hypervisor Platform，并按提示重启。
2. 运行 `Configure-Bluetooth.cmd`，选择专供安卓使用的适配器。在 Zadig 中核对 VID/PID，再切换为 **WinUSB**。该适配器将由安卓独占，Windows 无法同时使用；使用蓝牙键鼠时请准备其他输入设备。
3. 双击 `Start-PulseRelay.cmd`。v0.2.1 在线版或已应用补丁的完整包，默认简体中文、中国地区、上海时区。
4. 在 LSPosed 中确认 PulseRelay 已启用，作用域为 `com.mi.health`；在国内版小米运动健康内自行登录、添加手环。
5. 日常退出使用 `Stop-PulseRelay.cmd`，等待窗口和进程完全关闭后再移动目录。

模块设置入口：小米运动健康 → 我的 → 关于，长按图标。若 OBS 在同一台 Windows 上运行，UDP 接收目标可填写 `10.0.2.2:18181`；本项目未安装 OBS 插件，也未预设心率接收端。

### 恢复 Windows 蓝牙

双击 `Restore-WindowsBluetooth.cmd` 并允许管理员权限。脚本会先停止模拟器和桥接，再恢复所选适配器的 Windows 驱动；若提示重启，请重启。

切换 WinUSB 后，适配器可能位于设备管理器的“通用串行总线设备”分类，而不在“蓝牙”分类中。恢复 Windows 驱动后，需再次切换 WinUSB 才能供安卓桥接使用。

Realtek RTL8922AE（`13D3:3617`）使用专用固件初始化，恢复 Windows 时使用华硕提供的专用驱动及 SHA256 校验；完整运行环境带有对应缓存，缺失时才需下载。其他适配器恢复时需要匹配的原厂驱动备份。详细迁移说明见 [PORTABLE-README.md](PORTABLE-README.md)。

## 组件与验证范围

| 组件 | 版本 |
| --- | --- |
| Android | 12 / API 31 Google APIs x86_64，支持 ARM64 转译 |
| Emulator | 37.1.11 |
| Magisk | 25.2 |
| LSPosed | 1.9.2 / Zygisk |
| 国内版小米运动健康 | 3.59.2 / `com.mi.health` |
| PulseRelay | 3.1.0 发布 APK；内部版本为 3.0.1（301） |
| Bumble | 0.0.236 |

运行环境从全新安卓数据盘预装，验证系统账号数量为 0，不带原实例的账号、手环绑定或宿主机 ADB 私钥。

已验证：含空格路径迁移启动、在线安装、HTTP/SOCKS5 下载与续传、分卷及整包校验、Root、LSPosed、7 个心率 Hook，以及实际 `zh-CN`/`zh-rCN` 系统语言和 `Asia/Shanghai` 时区。完整包补丁验证了原脚本备份、配置/数据保留及异常校验拒绝。

Intel AX211 曾在原电脑实测；Realtek RTL8922AE 加载固件后，已在宿主机扫描和安卓配对页面发现附近 BLE 设备。**发现附近设备及 Hook 加载不代表特定手环已绑定，也不代表 OBS 已收到心率。** 特定手环的发现、绑定与心率发送仍需验证，其他蓝牙适配器不能据此保证兼容。

## 源码、打包与依赖

Git 仅提交脚本、配置示例、诊断源码、文档和许可证。镜像、APK、工具二进制、日志、驱动备份及个人配置不进入 Git。仅克隆源码不会自动安装运行环境，普通用户请使用 Releases 中的安装器或完整包。

- `installer/`：在线安装脚本、代理配置示例及固定下载清单。
- `patches/full-package/`：完整包更新器和说明。
- `scripts/Start-PulseRelay.ps1`、`Stop-PulseRelay.ps1`：启动及关闭；`Set-AndroidDefaults.ps1` 设置语言和地区默认值。
- `scripts/bluetooth_bridge.py`、`realtek_8922.py`：HCI/netsim 桥接、Intel 及 Realtek 固件初始化。
- `scripts/build_online_installer.py`、`build_full_update.py`：生成轻量安装器和完整包补丁。
- `scripts/stage_release.py`、`archive_release.py`：完整运行环境的准备和压缩校验工具。
- `diagnostics/`：BLE 诊断应用源码，构建另需 JDK、build-tools 36 和 API 34。

在线安装器固定依赖 v0.1.2 的运行环境资产，请保留该发布的分卷；更换运行环境时需同步更新下载清单中的 URL、大小和 SHA256，并重新验证安装。不要从已登录的个人实例直接制作公开包。组件来源与许可见 [THIRD-PARTY.md](THIRD-PARTY.md)。

## 上游项目

- [PulseRelay 模块](https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay)
- [OBS 接收插件](https://github.com/ChlorophyTeio/heart-rate-obs-plugin)
- [Bumble](https://google.github.io/bumble/platforms/android.html)
- [LSPosed](https://github.com/LSPosed/LSPosed)
- [rootAVD](https://gitlab.com/newbit/rootAVD)
