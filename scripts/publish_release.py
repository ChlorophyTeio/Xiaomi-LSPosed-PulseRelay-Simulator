"""Publish a verified portable ZIP as resumable, checksummed GitHub release parts."""
import argparse,concurrent.futures,hashlib,json,subprocess,time
from pathlib import Path
import requests
p=argparse.ArgumentParser();p.add_argument('--tag',required=True);p.add_argument('--archive',type=Path,required=True);p.add_argument('--body',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parent.parent
archive=a.archive.resolve(); digest=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()
expected=archive.with_suffix('.zip.sha256').read_text().split()[0]
if digest!=expected: raise RuntimeError('Archive checksum mismatch')
parts=[]
with archive.open('rb') as src:
    number=1
    while src.tell()<archive.stat().st_size:
        path=archive.with_name(archive.name+f'.part{number:03}')
        with path.open('wb') as dst:
            remaining=min(1024**3,archive.stat().st_size-src.tell())
            while remaining:
                block=src.read(min(8*1024**2,remaining));dst.write(block);remaining-=len(block)
        parts.append(path);number+=1
print(f'Prepared {len(parts)} release parts',flush=True)
sha=archive.with_suffix('.zip.sha256')
lines=[digest+'  '+archive.name]
for path in parts:
    with path.open('rb') as f: lines.append(hashlib.file_digest(f,'sha256').hexdigest()+'  '+path.name)
sha.write_text('\n'.join(lines)+'\n',encoding='ascii')
credential=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',capture_output=True,text=True,check=True)
fields=dict(x.split('=',1) for x in credential.stdout.splitlines() if '=' in x)
headers={'Authorization':'Bearer '+fields['password'],'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'}
base='https://api.github.com/repos/ChlorophyTeio/Xiaomi-LSPosed-PulseRelay-Simulator'
def call(method,url,**kwargs):
    r=requests.request(method,url,headers=headers,timeout=(30,3600),**kwargs)
    if not r.ok: raise RuntimeError(f'GitHub {method} HTTP {r.status_code}: '+r.json().get('message','Request failed'))
    return r.json() if r.content else None
# Drafts may not resolve through the tag endpoint until their tag is published.
# Find the newest matching draft explicitly so retries resume the same release.
matching=[r for r in call('GET',base+'/releases') if r['tag_name']==a.tag]
existing=max(matching,key=lambda r:r['id']) if matching else None
if existing is None:
    commit=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
    release=call('POST',base+'/releases',json={'tag_name':a.tag,'target_commitish':commit,'name':'Windows x64 Complete Portable '+a.tag,'body':a.body.read_text(encoding='utf-8-sig'),'draft':True})
else:
    release=existing
    if not release['draft']: raise RuntimeError('Refusing to modify an already published release')
    commit=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
    release=call('PATCH',base+'/releases/'+str(release['id']),json={'target_commitish':commit,'body':a.body.read_text(encoding='utf-8-sig')})
assets={x['name']:x for x in release['assets']}
files=parts+[sha,root/'scripts/Join-Release.ps1',root/'PORTABLE-README.md',root/'THIRD-PARTY.md']
url=release['upload_url'].split('{')[0]
def upload(path):
    with path.open('rb') as f: local_digest='sha256:'+hashlib.file_digest(f,'sha256').hexdigest()
    if path.name in assets:
        item=assets[path.name]
        if item.get('digest')==local_digest and item['size']==path.stat().st_size:
            print('Verified existing '+path.name,flush=True);return
        call('DELETE',base+'/releases/assets/'+str(item['id']))
    for attempt in range(3):
        try:
            print(f'Uploading {path.name}, attempt {attempt+1}',flush=True)
            with path.open('rb') as f:
                r=requests.post(url,params={'name':path.name},headers={**headers,'Content-Type':'application/octet-stream'},data=f,timeout=(30,180))
            if r.status_code!=201: raise RuntimeError(f'Asset {path.name}: HTTP {r.status_code}')
            item=r.json()
            if item['size']!=path.stat().st_size or item.get('digest')!=local_digest: raise RuntimeError('Uploaded asset verification failed: '+path.name)
            print('Uploaded and verified '+path.name,flush=True);return
        except requests.RequestException:
            current=call('GET',base+f'/releases/{release["id"]}/assets')
            found=next((x for x in current if x['name']==path.name),None)
            if found and found.get('digest')==local_digest: print('Verified completed '+path.name,flush=True);return
            if found: call('DELETE',base+'/releases/assets/'+str(found['id']))
            if attempt==2: raise
            time.sleep(3)
for path in files: upload(path)
release=call('PATCH',base+'/releases/'+str(release['id']),json={'tag_name':a.tag,'draft':False,'make_latest':'true'})
print('PUBLISHED '+release['html_url'],flush=True)
