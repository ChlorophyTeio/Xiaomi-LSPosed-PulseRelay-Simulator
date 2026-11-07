# 组件来源与许可文件

- Android Emulator、Platform Tools、Google APIs Android 12 镜像来自 Google Android SDK；保留各目录的 LICENSE、NOTICE 与镜像 NOTICE.txt。镜像下载索引：https://dl.google.com/android/repository/sys-img/google_apis/sys-img2-3.xml
- Magisk 25.2：https://github.com/topjohnwu/Magisk （GPL-3.0）。
- LSPosed 1.9.2：https://github.com/LSPosed/LSPosed （GPL-3.0）。
- PulseRelay 指定发布 APK：https://github.com/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay/releases/download/3.1.0/PulseRelay-310.apk （项目 MIT）。APK SHA256：6a52b5b557712da9ec9ecf9504ff3c08e3af4bf069bf7d8031bbc0f68aecb7c8。
- 小米运动健康国内版：https://hlth.io.mi.com/download?appId=mifitness ，小米专有软件，包内未修改 APK。SHA256：112e603b8342cb134402a6dcabdf3ec16fd5171ec65a1d5f7cb7efd83cb0995d。
- Python 3.14.6 Windows embeddable：https://www.python.org/ftp/python/3.14.6/python-3.14.6-embed-amd64.zip ，Python 软件基金会许可，保留 python 目录 LICENSE。
- Bumble：https://github.com/google/bumble （Apache-2.0）；其他 Python 包的许可证保留在 runtime/python/Lib/site-packages 各 dist-info 目录。已安装版本见 requirements-installed.txt。
- Intel 固件：https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git ，许可见包内 LICENSE.intel。
- Google AEHD 2.2：https://github.com/google/android-emulator-hypervisor-driver/releases/tag/v2.2 ，GPL-2.0。
- Zadig 2.9：https://github.com/pbatard/libwdi （GPL-3.0 / libwdi LGPL）。
- rootAVD：https://gitlab.com/newbit/rootAVD ，许可证保留在 downloads/rootAVD-LICENSE；干净系统的 Magisk ramdisk 由它生成。

该压缩包用于用户在自己的 Windows 设备间迁移。公开再分发前应自行核对各专有组件及 Google SDK/ARM 转译许可允许的使用和分发范围。

- Realtek RTL8922AU Bluetooth firmware: https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/rtl_bt ; SHA256 112290ca9dc3985034f572594812f0deb8530dd031686461b55cac43a1c35a79. Redistribution terms are retained as runtime/LICENCE.rtlwifi_firmware.txt. The initializer uses the vendor HCI protocol documented by Linux btrtl and Bumble; it loads volatile controller RAM only.
- ASUS Realtek Windows Bluetooth driver cache: https://www.asus.com/tw/supportonly/rog%20strix%20b850-g%20gaming%20wifi%20s/helpdesk_download/ ; ZIP SHA256 C4346316B2F8EB7F2E13BDC70C05687E14315EF8FCE2435449CD817E5A93FAA2. Used only to restore Windows Bluetooth; not a replacement for the HCI bridge firmware.
