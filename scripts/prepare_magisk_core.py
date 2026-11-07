"""Restore Magisk's packaged user-space tools for rootAVD installations."""
from pathlib import Path, PurePosixPath
from zipfile import ZipFile
root = Path(__file__).resolve().parent.parent
destination = root / 'runtime/magisk-core'
destination.mkdir(parents=True, exist_ok=True)
with ZipFile(root / 'downloads/Magisk-v25.2.apk') as archive:
    for name in archive.namelist():
        if name.endswith('/'):
            continue
        if name.startswith('assets/'):
            target = destination / name.removeprefix('assets/')
        elif name.startswith('lib/x86_64/') and name.endswith('.so'):
            target = destination / PurePosixPath(name).name[3:-3]
        else:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(archive.read(name))
