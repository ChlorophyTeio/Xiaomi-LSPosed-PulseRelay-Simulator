"""Build the small online installer using explicitly selected bundled tools."""
import argparse,hashlib,shutil,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--resources-source',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
repo=Path(__file__).resolve().parent.parent
source=a.resources_source.resolve();output=a.output.resolve()
if output.exists(): raise RuntimeError('Output already exists')
stage=output.parent/'PulseRelay-OnlineInstaller'
if stage.exists(): raise RuntimeError('Installer staging directory already exists')
stage.mkdir(parents=True)
for name in ('Install.cmd','Configure-Download-Proxy.cmd','Run-Zadig.cmd','Install-Acceleration.cmd','download-settings.example.json','payload-manifest.json','README.md','scripts','licenses'):
    src=repo/'installer'/name;dst=stage/name
    if src.is_dir():shutil.copytree(src,dst)
    else:shutil.copy2(src,dst)
shutil.copy2(stage/'download-settings.example.json',stage/'download-settings.json')
shutil.copy2(repo/'THIRD-PARTY.md',stage/'THIRD-PARTY.md')
(stage/'tools').mkdir()
zadig=source/'downloads/zadig-2.9.exe'
if hashlib.sha256(zadig.read_bytes()).hexdigest()!='4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b':raise RuntimeError('Unexpected Zadig binary')
shutil.copy2(zadig,stage/'tools'/zadig.name)
shutil.copytree(source/'runtime/aehd',stage/'tools/aehd')
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for path in sorted(stage.rglob('*')):
        if path.is_file(): z.write(path,Path(stage.name)/path.relative_to(stage))
with zipfile.ZipFile(output) as z:
    bad=z.testzip()
    if bad:raise RuntimeError('ZIP CRC failure: '+bad)
digest=hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(digest+'  '+output.name+'\n',encoding='ascii')
print(f'Built {output} ({output.stat().st_size/1024**2:.2f} MiB), SHA256 {digest}')
