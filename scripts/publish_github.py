"""Publish the audited source repository's clean binary bundle as release assets."""
from pathlib import Path
import subprocess, os, hashlib, concurrent.futures
import requests

root = Path(__file__).resolve().parent.parent
repository = 'ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator'
git = os.environ.get('GIT_EXE', 'git')
credential = subprocess.run([git,'credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True)
fields = dict(line.split('=',1) for line in credential.stdout.splitlines() if '=' in line)
headers = {'Authorization':'Bearer '+fields['password'],'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'}
base = 'https://api.github.com/repos/'+repository
def call(method,url,**kwargs):
    response = requests.request(method,url,headers=headers,timeout=(30,3600),**kwargs)
    if not response.ok: raise RuntimeError(f'GitHub {method} {response.status_code}: {response.json().get("message", "request failed")}')
    return response.json() if response.content else None
repo = call('GET',base)
if not repo.get('permissions',{}).get('push'): raise RuntimeError('GitHub push permission is missing')
archive = root/'dist/PulseRelay-Windows-Clean.zip'
parts = []
with archive.open('rb') as src:
    for number in range(1,5):
        path = archive.with_name(archive.name+f'.part{number:03}')
        remaining = min(1024**3, archive.stat().st_size - src.tell())
        with path.open('wb') as dest:
            while remaining:
                block = src.read(min(8*1024**2, remaining))
                if not block: raise RuntimeError('Unexpected archive EOF')
                dest.write(block); remaining -= len(block)
        parts.append(path)
print('Four release parts prepared',flush=True)
response = requests.get(base+'/releases/tags/v0.1.0',headers=headers,timeout=30)
if response.status_code == 404:
    release = call('POST',base+'/releases',json={'tag_name':'v0.1.0','target_commitish':'main','name':'Windows x64 干净预装包 v0.1.0','draft':True,'body':'Android 12 + Magisk 25.2 + LSPosed 1.9.2 + 国内版小米运动健康 3.59.2 + PulseRelay。\n\n下载全部四个分卷、SHA256 文件和 Join-Release.ps1，放在同一文件夹，运行合并脚本后解压到 NTFS 磁盘。然后按 PORTABLE-README.md 配置虚拟化、加速驱动与独占 WinUSB 蓝牙。\n\n此干净包没有登录账号或手环绑定；已验证换目录启动、Root、LSPosed、PulseRelay 7 个 Hook 与 ZIP CRC。不同电脑的蓝牙适配器仍需实测兼容。PulseRelay-310.apk 的内部版本标记为 3.0.1（301）。'})
else:
    response.raise_for_status(); release = response.json()
assets = {item['name']:item for item in call('GET',base+f'/releases/{release["id"]}/assets')}
files = parts+[archive.with_suffix('.zip.sha256'),root/'scripts/Join-Release.ps1',root/'PORTABLE-README.md',root/'THIRD-PARTY.md']
upload_url = release['upload_url'].split('{')[0]
def upload(path):
    if path.name in assets:
        if assets[path.name]['size'] != path.stat().st_size: raise RuntimeError('Existing release asset has unexpected size: '+path.name)
        print('Already uploaded '+path.name,flush=True); return
    with path.open('rb') as data:
        result = requests.post(upload_url,params={'name':path.name},data=data,headers={**headers,'Content-Type':'application/octet-stream'},timeout=(30,3600))
    if result.status_code != 201: raise RuntimeError(f'Asset upload failed: {path.name}: HTTP {result.status_code}')
    if result.json()['size'] != path.stat().st_size: raise RuntimeError('Asset size mismatch')
    remote_digest = result.json().get('digest')
    if remote_digest:
        with path.open('rb') as content:
            local_digest = 'sha256:'+hashlib.file_digest(content,'sha256').hexdigest()
        if remote_digest != local_digest: raise RuntimeError('Remote asset checksum mismatch: '+path.name)
    print('Uploaded '+path.name,flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    list(pool.map(upload,files))
published = call('PATCH',base+f'/releases/{release["id"]}',json={'draft':False})
print('PUBLISHED '+published['html_url'],flush=True)
