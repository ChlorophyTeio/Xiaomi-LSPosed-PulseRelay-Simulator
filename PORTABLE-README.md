# Windows 干净迁移包

仅适用于 Windows 11 x64、Intel/AMD 处理器且已开启硬件虚拟化的电脑。Windows ARM 设备未验证，不属于此包支持范围。

1. 完整解压到本机磁盘；不要直接在压缩包内运行。
2. 首次使用以管理员权限运行 `First-Run-Drivers.cmd` 检查/安装 Google AEHD 加速驱动。若电脑使用 Hyper-V，请启用 Windows Hypervisor Platform；按 Windows 提示重启。
3. 运行 `Configure-Bluetooth.cmd`，选择专供安卓使用的蓝牙适配器。脚本备份原驱动并启动 Zadig；在 Zadig 中核对 VID/PID，再将此设备切换为 WinUSB。若要求重启，请重启。
4. 双击 `Start-PulseRelay.cmd`。首次进入 LSPosed → 模块 → PulseRelay，确认“启用模块”已开启、作用域勾选“小米运动健康（com.mi.health）”；然后强制停止并重开小米运动健康。在国内版小米运动健康中重新登录，并绑定手环。日常退出使用 `Stop-PulseRelay.cmd`。

包内包含 Android 12 ARM64 转译镜像、Magisk 25.2、LSPosed 1.9.2、国内版小米运动健康 3.59.2、用户指定的 PulseRelay-310.apk、独立 Android Emulator、Python 与 Bumble。无需另装 Android Studio 或 Python。

PulseRelay 的发布文件名为 310，但 APK 内部版本是 3.0.1（301），保留原文件未修改。作用域为 `com.mi.health`；设置入口：小米运动健康 → 我的 → 关于，长按图标。OBS 在这台 Windows 上运行时，可将 UDP 目标设为 `10.0.2.2:18181`；此包没有安装 OBS 插件，也未预设心率发送目标。

此干净包使用新建安卓数据，未复制原模拟器的小米账号、手环绑定、应用私有数据或 ADB 主机私钥。已安装的框架和应用可以保留自身初始化设置。不要直接把本机登录过的 userdata 文件替换进去后再公开分享。

蓝牙桥接需独占适配器。Intel AX211 已在原电脑实测，其他型号需要对应的固件/驱动支持，不能保证任意蓝牙适配器兼容。最方便的方式是使用独立 USB 蓝牙适配器。不同电脑的蓝牙地址不同，手环需要重新配对。

`config.json` 中代理默认为 `127.0.0.1:7897`，新电脑需运行相同端口的代理，或自行修改代理配置。ADB 端口默认 5580，桥接仅监听本机 8877；同一套包不要同时启动两份。

恢复 Windows 蓝牙：先停止模拟器，在设备管理器中对所选适配器“更新驱动程序 → 浏览我的电脑 → 让我选取”，选择原厂蓝牙驱动；原始驱动备份位于 `runtime/bluetooth-original`。按 Windows 提示重启。

分发时请保留软件自带的 LICENSE、NOTICE 文件及 `THIRD-PARTY.md`。这是多项开源/免费工具的本机部署组合，后续公开再分发还应核对各组件许可范围，尤其 Google 系统镜像的 SDK/ARM 转译使用条款。

恢复 Windows 蓝牙：双击 Restore-WindowsBluetooth.cmd 并允许管理员权限。Realtek RTL8922AE（13D3:3617）首次运行需联网下载并校验华硕专用驱动；其他适配器需有效的原厂驱动备份。恢复后如仍无法搜索，请确认外置天线、目标设备配对模式，并重启 Windows 后重试。不要重新运行 Configure-Bluetooth.cmd，除非要把适配器再次交给安卓独占。
