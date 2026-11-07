"""Archive an offline, sanitized portable directory and verify every ZIP entry."""
import argparse,hashlib,json,time,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--archive',type=Path,required=True);a=p.parse_args()
source=a.source.resolve();archive=a.archive.resolve()
if archive.exists(): raise RuntimeError('Archive already exists')
config=json.loads((source/'config.json').read_text(encoding='utf-8-sig'))
if config['controller']!='UNCONFIGURED' or 'bluetoothInstanceId' in config: raise RuntimeError('Personal Bluetooth configuration remains')
guest_files={'config.ini','qemu-version.txt','version_num.cache','cache.img','cache.img.qcow2','encryptionkey.img','encryptionkey.img.qcow2','userdata-qemu.img','userdata-qemu.img.qcow2'}
def include(path):
    rel=path.relative_to(source)
    if not path.is_file() or '__pycache__' in rel.parts or path.suffix=='.pyc': return False
    if rel.parts[0]=='logs' or str(rel).replace('\\','/')=='runtime/bridge.pid': return False
    if rel.parts[:2]==('runtime','android-home'):
        return rel.parts[2:4]==('avd','PulseRelay12.avd') and len(rel.parts)==5 and rel.name in guest_files
    return True
files=sorted(p for p in source.rglob('*') if include(p))
for path in files:
    if path.name.lower().startswith('adbkey') or path.name.endswith('.lock'): raise RuntimeError('Runtime identity or lock remains: '+str(path))
print(f'Archiving {len(files)} files; input {sum(p.stat().st_size for p in files)/1024**3:.2f} GiB',flush=True)
last=time.monotonic()
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=1,allowZip64=True) as z:
    for i,path in enumerate(files):
        z.write(path,Path(source.name)/path.relative_to(source))
        if time.monotonic()-last>15:
            print(f'{i+1}/{len(files)}; compressed {archive.stat().st_size/1024**3:.2f} GiB',flush=True);last=time.monotonic()
print('Verifying complete ZIP CRC...',flush=True)
with zipfile.ZipFile(archive) as z:
    bad=z.testzip()
    if bad: raise RuntimeError('ZIP CRC failed: '+bad)
with archive.open('rb') as f: digest=hashlib.file_digest(f,'sha256').hexdigest()
archive.with_suffix('.zip.sha256').write_text(digest+'  '+archive.name+'\n',encoding='ascii')
print(f'VERIFIED {archive.stat().st_size} bytes SHA256 {digest}',flush=True)
