from pathlib import Path
import sqlite3, sys
root = Path(__file__).resolve().parent.parent
source = sqlite3.connect(root/'runtime/clean-modules.db')
target = sqlite3.connect(root/'runtime/clean-modules-fixed.db')
source.backup(target)
with target:
    target.execute('INSERT INTO modules(module_pkg_name,apk_path,enabled) VALUES(?,?,1) ON CONFLICT(module_pkg_name) DO UPDATE SET apk_path=excluded.apk_path,enabled=1', ('website.xihan.pbra', sys.argv[1]))
    mid = target.execute('SELECT mid FROM modules WHERE module_pkg_name=?', ('website.xihan.pbra',)).fetchone()[0]
    target.execute('INSERT OR IGNORE INTO scope(mid,app_pkg_name,user_id) VALUES(?,?,0)', (mid,'com.mi.health'))
target.execute('PRAGMA wal_checkpoint(TRUNCATE)')
target.execute('PRAGMA journal_mode=DELETE')
print(target.execute('SELECT module_pkg_name,enabled FROM modules').fetchall())
print(target.execute('SELECT * FROM scope').fetchall())
target.close()
source.close()
