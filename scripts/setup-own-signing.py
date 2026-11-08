#!/usr/bin/env python3
import os
from pathlib import Path
import secrets
import shutil
import subprocess


def main():
    destination = Path(os.environ.get(
        'GYMMANE_SIGNING_PROPERTIES',
        Path.home() / '.local/share/gymmane-own/signing.properties',
    )).expanduser().resolve()
    repository = Path(__file__).resolve().parents[1]
    if repository == destination or repository in destination.parents:
        raise SystemExit('Keep signing files outside the Git repository.')
    if destination.exists():
        print(f'Signing configuration already exists; preserved: {destination}')
        return
    keystore = destination.parent / 'gymmane-own-release.jks'
    if keystore.exists():
        raise SystemExit('A keystore already exists without configuration. Restore its configuration; do not replace it.')
    java_home = os.environ.get('JAVA_HOME')
    keytool = str(Path(java_home) / 'bin/keytool') if java_home else shutil.which('keytool')
    if not keytool:
        raise SystemExit('Java 17 keytool is required.')
    destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    password = secrets.token_urlsafe(36)
    env = dict(os.environ, GYMMANE_KEY_PASSWORD=password)
    previous_umask = os.umask(0o077)
    try:
        subprocess.run([
            keytool, '-genkeypair', '-noprompt', '-storetype', 'JKS',
            '-keystore', str(keystore), '-alias', 'gymmane-own',
            '-keyalg', 'RSA', '-keysize', '4096', '-validity', '36500',
            '-dname', 'CN=GymMane Own',
            '-storepass:env', 'GYMMANE_KEY_PASSWORD',
            '-keypass:env', 'GYMMANE_KEY_PASSWORD',
        ], env=env, check=True)
        with destination.open('x') as stream:
            stream.write(f'storeFile={keystore}\nkeyAlias=gymmane-own\n')
            stream.write(f'storePassword={password}\nkeyPassword={password}\n')
        keystore.chmod(0o600)
        destination.chmod(0o600)
    finally:
        os.umask(previous_umask)
    print(f'Created private signing configuration: {destination}')
    print('Back up this directory securely. No passwords were printed.')


if __name__ == '__main__':
    main()
