# 完整包更新补丁 v0.2.1

适用于完整即用包 v0.1.2，也可用于在线安装器安装后的 PulseRelay 目录。补丁不包含模拟器、安卓镜像或 APK，无需重新下载 3.66 GiB 运行环境。

1. 用原目录中的 Stop-PulseRelay.cmd 关闭模拟器，等待完全退出。
2. 将本补丁解压到一个新文件夹，双击 Apply-FullPackage-Update.cmd。
3. 输入原安装目录，即同时包含 config.json、scripts、runtime 的目录。若补丁文件夹位于原安装目录下，会自动识别父目录。
4. 提示 Updated 后，使用原 Start-PulseRelay.cmd 启动。

更新后的默认设置：简体中文（zh-CN）、国家/地区中国、上海时区（Asia/Shanghai，UTC+8），关闭自动时区。首次切换语言时安卓会自动重启一次。

更新器只校验并替换两个启动相关脚本：Set-AndroidDefaults.ps1、Start-PulseRelay.ps1。旧脚本备份在原目录的 updates/backups/v0.2.1-时间-编号 下。config.json、蓝牙适配器选择、应用、账号、配对记录和安卓数据盘均不修改。运行更新器本身不会启动模拟器或切换蓝牙驱动。

如需回退，关闭模拟器，将备份目录中的脚本复制回原 scripts 目录即可；新增的辅助脚本可以保留。此补丁不负责修复缺少 Realtek 固件支持的更早版本，也不代表特定手环已经完成绑定。
