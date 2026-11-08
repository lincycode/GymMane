#!/usr/bin/env python3
from pathlib import PurePosixPath
import subprocess


def git(*args):
    return subprocess.check_output(['git', *args])


errors = []
for raw in git('diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z').split(b'\0'):
    if not raw:
        continue
    name = raw.decode()
    path = PurePosixPath(name)
    if any(part in {'.toolchain', 'artifacts', 'build', '.dart_tool', '.pub-cache'} for part in path.parts):
        errors.append(f'Generated artifact: {name}')
    if path.suffix.lower() in {'.apk', '.aab', '.jks', '.keystore', '.db', '.sqlite', '.zip'}:
        errors.append(f'Binary or private data: {name}')
    if path.name in {'key.properties', 'own-signing.properties', 'signing.properties', '.env'}:
        errors.append(f'Private configuration: {name}')
    size = int(git('cat-file', '-s', f':{name}'))
    if size > 5 * 1024 * 1024:
        errors.append(f'File exceeds 5 MiB: {name}')
if errors:
    raise SystemExit('\n'.join(errors))
print('Staged files checked: no generated artifacts or signing files.')
