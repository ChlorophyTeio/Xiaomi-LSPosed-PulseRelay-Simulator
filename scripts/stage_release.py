"""Stage immutable runtime resources; never copy guest disks or host identities."""
import argparse,json,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
repo=Path(__file__).resolve().parent.parent
out=a.output.resolve(); source=a.source.resolve()
if out.exists(): raise RuntimeError('Use a new output directory')
out.mkdir(parents=True)
def copy(src,dst):
    dst=out/dst;dst.parent.mkdir(parents=True,exist_ok=True)
    if src.is_dir(): shutil.copytree(src,dst,ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    else: shutil.copy2(src,dst)
for name in ('scripts','README.md','PORTABLE-README.md','THIRD-PARTY.md','config.example.json'):
    copy(repo/name,name)
for path in repo.glob('*.cmd'): copy(path,path.name)
for name in ('runtime/python','runtime/sdk','runtime/aehd','runtime/intel-firmware','runtime/magisk-core','apks','downloads'):
    copy(source/name,name)
for name in ('rtl8922au_fw.bin','LICENCE.rtlwifi_firmware.txt','realtek-bluetooth.zip'):
    copy(source/'runtime'/name,'runtime/'+name)
# Embedded SDK's data directory contains only stock image initialization data.
config=json.loads((repo/'config.example.json').read_text())
config.update(adbPort=5582,bridgePort=8879)
(out/'config.json').write_text(json.dumps(config,indent=2),encoding='utf-8')
(out/'logs').mkdir();(out/'runtime/android-home').mkdir()
print('Clean runtime staged at',out,flush=True)
