"""Build a script-only, checksummed update for existing v0.1.2 full packages."""
import argparse,hashlib,json,shutil,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',required=True,type=Path);a=p.parse_args()
repo=Path(__file__).resolve().parent.parent;out=a.output.resolve();stage=out.parent/'PulseRelay-FullPackage-Update-v0.2.1'
if out.exists() or stage.exists():raise RuntimeError('Use a new output directory')
stage.mkdir(parents=True)
for name in ('Apply-FullPackage-Update.cmd','Apply-FullPackage-Update.ps1','README.md'):shutil.copy2(repo/'patches/full-package'/name,stage/name)
(stage/'payload').mkdir();files=[]
for name in ('Set-AndroidDefaults.ps1','Start-PulseRelay.ps1'):
    source=repo/'scripts'/name;shutil.copy2(source,stage/'payload'/name)
    files.append(dict(name=name,sha256=hashlib.sha256(source.read_bytes()).hexdigest()))
(stage/'patch-manifest.json').write_text(json.dumps(dict(version='0.2.1',files=files),indent=2)+'\n',encoding='utf-8')
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for path in sorted(stage.rglob('*')):
        if path.is_file():z.write(path,Path(stage.name)/path.relative_to(stage))
with zipfile.ZipFile(out) as z:assert z.testzip() is None
digest=hashlib.sha256(out.read_bytes()).hexdigest();out.with_suffix('.zip.sha256').write_text(digest+'  '+out.name+'\n',encoding='ascii')
print(f'Built {out}: {out.stat().st_size} bytes, SHA256 {digest}')
