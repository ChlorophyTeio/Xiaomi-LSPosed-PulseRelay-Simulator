from pathlib import Path
import zipfile, json, hashlib, time
root = Path(__file__).resolve().parent.parent
source = root / 'dist/Relocation Test/PulseRelay-Windows-Clean'
archive = root / 'dist/PulseRelay-Windows-Clean.zip'
config = json.loads((source/'config.json').read_text(encoding='utf-8-sig'))
config.update(adbPort=5580, controller='UNCONFIGURED')
(source/'config.json').write_text(json.dumps(config,indent=2))
# Runtime state is generated on the target computer. Retain guest disks/config only.
avd = source/'runtime/android-home/avd/PulseRelay12.avd'
for name in ['hardware-qemu.ini','emu-launch-params.txt','multiinstance.lock','AVD.conf','netsim.ini','read-snapshot.txt']:
    for attempt in range(60):
        try:
            (avd/name).unlink(missing_ok=True)
            break
        except PermissionError:
            if attempt == 59: raise
            time.sleep(1)
for path in (source/'logs').iterdir():
    if path.is_file(): path.unlink()
for name in ['Build-BleCheck.ps1','Install-Root.ps1','stage_portable.py']:
    (source/'scripts'/name).unlink(missing_ok=True)
files = sorted(p for p in source.rglob('*') if p.is_file() and '__pycache__' not in p.parts and not p.name.endswith('.pyc'))
print(f'Archiving {len(files)} files; input {sum(p.stat().st_size for p in files)/1024**3:.2f} GiB',flush=True)
last = time.monotonic()
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=1,allowZip64=True) as z:
    for i,path in enumerate(files):
        z.write(path, Path(source.name)/path.relative_to(source))
        if time.monotonic()-last > 15:
            print(f'{i+1}/{len(files)} files; archive {archive.stat().st_size/1024**3:.2f} GiB',flush=True)
            last = time.monotonic()
print('Verifying archive CRC...',flush=True)
with zipfile.ZipFile(archive) as z:
    bad = z.testzip()
    if bad: raise RuntimeError(f'Archive CRC failed: {bad}')
digest = hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()
archive.with_suffix('.zip.sha256').write_text(digest+'  '+archive.name+'\n')
print(f'COMPLETE {archive.stat().st_size} bytes SHA256 {digest}',flush=True)
