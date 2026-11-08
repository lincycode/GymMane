#!/usr/bin/env python3
"""Capture an explicitly selected emulator; keep UI evidence outside Git."""
import argparse
from datetime import date
import os
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('serial')
parser.add_argument('name')
args = parser.parse_args()
if not re.fullmatch(r'emulator-\d+', args.serial):
    parser.error('Use an isolated emulator serial; this helper does not target phones.')
if not re.fullmatch(r'[a-z0-9-]+', args.name):
    parser.error('Use a lowercase capture name with digits or hyphens.')
sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
if not sdk:
    parser.error('Set ANDROID_HOME before capturing.')
adb = [str(Path(sdk) / 'platform-tools/adb'), '-s', args.serial]
root = Path(__file__).resolve().parents[1]
output = root / 'artifacts/qa' / date.today().isoformat() / 'screens'
output.mkdir(parents=True, exist_ok=True)


def run(*command):
    return subprocess.check_output([*adb, *command], timeout=45)


run('shell', 'rm', '-f', '/sdcard/gymmane-qa.xml')
result = run('shell', 'uiautomator', 'dump', '/sdcard/gymmane-qa.xml')
if b'UI hierchary dumped' not in result and b'UI hierarchy dumped' not in result:
    raise SystemExit('UI capture did not settle; retry after inspecting the emulator state.')
xml = run('exec-out', 'cat', '/sdcard/gymmane-qa.xml')
(output / f'{args.name}.xml').write_bytes(xml)
png = run('exec-out', 'screencap', '-p')
if not png.startswith(b'\x89PNG\r\n\x1a\n'):
    raise SystemExit('Capture did not return a PNG; inspect the emulator before retrying.')
(output / f'{args.name}.png').write_bytes(png)
for node in ET.fromstring(xml).iter('node'):
    label = node.get('text') or node.get('content-desc')
    if label and node.get('bounds') != '[0,0][0,0]':
        print(label, node.get('bounds'))
print(output / f'{args.name}.png')
