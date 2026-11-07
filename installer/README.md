# PulseRelay 轻量在线安装包

随包携带 Zadig 2.9 和 AEHD 2.2 加速驱动。模拟器、Python、安卓镜像及预装应用在首次安装时下载，后续启动无需重复下载。

## 使用

1. 完整解压到本地磁盘。建议预留 30 GB 空间，避免在压缩包内运行。
2. 需要代理时先双击 `Configure-Download-Proxy.cmd`，修改配置并保存。
3. 双击 `Install.cmd`。首次下载约 **3.66 GiB**，自动校验全部分卷和整包 SHA256，再解压到本目录下的 `PulseRelay` 文件夹。
4. 进入安装后的 `PulseRelay`：运行 `First-Run-Drivers.cmd` 检查虚拟化加速，运行 `Configure-Bluetooth.cmd` 并在 Zadig 中核对设备、切换 WinUSB，然后运行 `Start-PulseRelay.cmd`。
5. 在小米运动健康中自行登录、添加手环。恢复 Windows 蓝牙使用安装目录中的 `Restore-WindowsBluetooth.cmd`。

安装器采用已验证的 v0.1.2 运行环境，保留预装的 Root、LSPosed 和 PulseRelay 作用域。它不会在首次安装时重新下载并组合不确定版本的组件，也不会自动更换蓝牙驱动。特定手环的发现、绑定和心率发送仍需验证。

## 下载代理配置

`download-settings.json` 只控制安装器下载；安卓应用的代理在安装目录的 `config.json` 中另行配置。

直连（默认）：

```json
{"downloadProxyMode":"direct","downloadProxyUrl":"http://127.0.0.1:7897"}
```

HTTP 代理：

```json
{"downloadProxyMode":"custom","downloadProxyUrl":"http://127.0.0.1:7897"}
```

SOCKS5 代理（由代理解析域名）：

```json
{"downloadProxyMode":"custom","downloadProxyUrl":"socks5h://127.0.0.1:7897"}
```

`downloadProxyMode` 也可设为 `environment`，使用环境中的 `HTTPS_PROXY`、`HTTP_PROXY` 等设置；此模式不等同于自动读取 Windows 系统代理。

## 重试和路径

- 下载失败后保留 `cache` 中的文件，重新运行 `Install.cmd` 会续传未完成的分卷，并跳过已校验的分卷。
- 安装不会覆盖已有目录、账号或安卓数据。可用 PowerShell 的 `-InstallDirectory D:\PulseRelay` 参数指定一个尚不存在的新目录。
- 安装成功后重复运行会检查已安装标记并退出。`-DownloadOnly` 可只下载和校验。
- 缓存保留以便重试，安装确认正常后可自行删除 `cache` 释放空间。
- `Run-Zadig.cmd` 和 `Install-Acceleration.cmd` 可在下载前启动随包小工具；需要修改驱动时 Windows 会请求管理员权限。

适用 Windows 11 x64 / Intel 或 AMD CPU；Windows ARM 不支持。运行环境和工具来源、许可证见 `THIRD-PARTY.md` 及随附工具目录。

维护者：在线安装器固定引用 v0.1.2 的运行环境资产；请保留这些资产。更换运行环境版本时同时更新 payload-manifest.json 中的 URL、大小和 SHA256，并重新验证安装。下载清单不携带 GitHub 令牌。
