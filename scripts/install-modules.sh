#!/system/bin/sh
set -e
magisk --sqlite "INSERT OR REPLACE INTO settings(key,value) VALUES('zygisk',1);"
magisk --sqlite "INSERT OR REPLACE INTO policies(uid,policy,until,logging,notification) VALUES(2000,2,0,1,1);"
BOOTMODE=true /data/adb/magisk/busybox ash /data/adb/magisk/module_installer.sh 1 1 /data/local/tmp/lsposed.zip
