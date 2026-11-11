#!/usr/bin/env python3
"""Verify the personal APK and prepare its public update manifest."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--previous-apk', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    os.chdir(root)
    properties = dict(line.split('=', 1) for line in Path('own.properties').read_text().splitlines() if '=' in line)
    version = properties['versionName']
    code = int(properties['versionCode']) * 10 + 2
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-own\.\d+)?', version):
        raise SystemExit('Invalid personal version name.')
    if properties['applicationId'] != 'com.echolin.gymmane':
        raise SystemExit('Unexpected application identity.')
    apk = root / f'artifacts/apk/EnoGym-{version}-Ace6T-arm64-v8a-release.apk'
    sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT'])
    versions = sorted((sdk / 'build-tools').iterdir(), key=lambda p: tuple(int(v) for v in re.findall(r'\d+', p.name)))
    build_tools = next(p for p in reversed(versions) if (p / 'apksigner').is_file() and (p / 'aapt').is_file())
    signer = build_tools / 'apksigner'

    def certificate(path):
        output = run(str(signer), 'verify', '--verbose', '--print-certs', str(path))
        matches = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-f]+)', output)
        if len(matches) != 1:
            raise SystemExit('Expected one verified signing certificate.')
        return matches[0]

    cert = certificate(apk)
    if args.previous_apk and certificate(args.previous_apk.resolve()) != cert:
        raise SystemExit('The signing certificate differs from the previous APK.')
    badging = run(str(build_tools / 'aapt'), 'dump', 'badging', str(apk))
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    minimum = re.search(r"sdkVersion:'(\d+)'", badging)
    if not package or package.groups() != (properties['applicationId'], str(code), version):
        raise SystemExit('APK package or version does not match own.properties.')
    if 'application-debuggable' in badging or "native-code: 'arm64-v8a'" not in badging or not minimum:
        raise SystemExit('Expected a non-debuggable arm64 APK with a minimum SDK.')
    dart_version = run(str(build_tools / 'aapt'), 'list', str(apk))
    if 'lib/arm64-v8a/libapp.so' not in dart_version:
        raise SystemExit('Missing Flutter release application.')
    hasher = hashlib.sha256()
    with apk.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    manifest = {
        'schemaVersion': 1,
        'applicationId': properties['applicationId'],
        'versionName': version,
        'versionCode': code,
        'minSdk': int(minimum.group(1)),
        'abi': 'arm64-v8a',
        'apkName': apk.name,
        'size': apk.stat().st_size,
        'sha256': digest,
        'signingCertificateSha256': cert,
        'sourceCommit': run('git', 'rev-parse', 'HEAD'),
    }
    directory = root / 'artifacts/releases' / version
    directory.mkdir(parents=True, exist_ok=True)
    shutil.copy2(apk, directory / apk.name)
    (directory / 'enogym-update.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (directory / f'{apk.name}.sha256').write_text(f'{digest}  {apk.name}\n')
    print(directory)
    print(f'Verified {version} ({code}), SHA-256 {digest}')


if __name__ == '__main__':
    main()
