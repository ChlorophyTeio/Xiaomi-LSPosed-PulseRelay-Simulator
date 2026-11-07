from pathlib import Path
import shutil, zipfile, json
root = Path(__file__).resolve().parent.parent
out = root / 'dist/PulseRelay-Windows-Clean'
out.mkdir(parents=True, exist_ok=True)
def copy(source, dest):
    source, dest = Path(source), out / dest
    if source.is_dir():
        shutil.copytree(source, dest, dirs_exist_ok=True, ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    else:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, dest)
for name in ['Start-PulseRelay.cmd','Stop-PulseRelay.cmd']:
    copy(root/name,name)
copy(root/'scripts','scripts')
copy(root/'apks/PulseRelay-310.apk','apks/PulseRelay-310.apk')
copy(root/'apks/MiFitness-official.apk','apks/MiFitness-official.apk')
copy(root/'runtime/lsposed-manager/manager.apk','apks/LSPosed-manager.apk')
for name in ['Magisk-v25.2.apk','LSPosed-v1.9.2-7024-zygisk-release.zip','zadig-2.9.exe','rootAVD-LICENSE']:
    copy(root/'downloads'/name,'downloads/'+name)
for name in ['aehd','intel-firmware','magisk-core']:
    copy(root/'runtime'/name,'runtime/'+name)
copy(root/'runtime/sdk/platform-tools','runtime/sdk/platform-tools')
copy(root/'runtime/sdk/system-images/android-31','runtime/sdk/system-images/android-31')
config = json.loads((root/'config.json').read_text(encoding='utf-8-sig'))
sdk = Path(config['sdk'])
if not sdk.is_absolute(): sdk = root/sdk
copy(sdk/'emulator','runtime/sdk/emulator')
print('Android runtime copied', flush=True)
with zipfile.ZipFile(root/'downloads/python-3.14.6-embed-amd64.zip') as z:
    z.extractall(out/'runtime/python')
(out/'runtime/python/python314._pth').write_text('python314.zip\n.\nLib/site-packages\nimport site\n')
copy(root/'runtime/bridge-venv/Lib/site-packages','runtime/python/Lib/site-packages')
config = json.loads((root/'config.json').read_text())
config.update(sdk='runtime/sdk',python='runtime/python/python.exe',adbPort=5582)
(out/'config.json').write_text(json.dumps(config,indent=2))
for name in ['logs','runtime/android-home']:
    (out/name).mkdir(parents=True,exist_ok=True)
print('Portable staging ready',flush=True)
