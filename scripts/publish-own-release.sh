#!/usr/bin/env bash
set -euo pipefail
GYMMANE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$GYMMANE_ROOT"
if [[ "$#" != 1 || ! -f "$1" ]]; then
  echo 'Usage: bash scripts/publish-own-release.sh path/to/release-notes.md' >&2
  exit 1
fi
GYMMANE_NOTES="$1"
if [[ "$(git branch --show-current)" != own || -n "$(git status --porcelain)" ]]; then
  echo 'Publish only a reviewed, committed, clean own branch.' >&2
  exit 1
fi
if [[ "$(git remote get-url origin)" != 'https://github.com/lincycode/GymMane.git' ]]; then
  echo 'Unexpected origin. Verify the personal repository before publishing.' >&2
  exit 1
fi
GYMMANE_VERSION="$(sed -n 's/^versionName=//p' own.properties)"
GYMMANE_COMMIT="$(git rev-parse HEAD)"
GYMMANE_TAG="enogym-v$GYMMANE_VERSION"
GYMMANE_DIRECTORY="artifacts/releases/$GYMMANE_VERSION"
python3 - "$GYMMANE_DIRECTORY" "$GYMMANE_COMMIT" <<'PY'
import hashlib, json, pathlib, re, subprocess, sys
directory = pathlib.Path(sys.argv[1])
manifest = json.loads((directory / 'enogym-update.json').read_text())
apk = directory / manifest['apkName']
if manifest['sourceCommit'] != sys.argv[2]:
    raise SystemExit('Prepare the release again after committing.')
hasher = hashlib.sha256()
with apk.open('rb') as source:
    for chunk in iter(lambda: source.read(1024 * 1024), b''):
        hasher.update(chunk)
if apk.stat().st_size != manifest['size'] or hasher.hexdigest() != manifest['sha256']:
    raise SystemExit('Prepared APK changed; prepare and verify again.')
releases = json.loads(subprocess.check_output([
    'gh', 'api', 'repos/lincycode/GymMane/releases?per_page=100',
]))
stable = [r for r in releases if not r['draft'] and not r['prerelease']]
if stable:
    latest = max(stable, key=lambda r: r['published_at'])
    previous = None
    version = re.fullmatch(r'enogym-v(\d+\.\d+\.\d+-own\.\d+)', latest['tag_name'])
    if version:
        cached = directory.parent / version[1] / 'enogym-update.json'
        asset = next((a for a in latest['assets'] if a['name'] == cached.name), None)
        if asset and cached.is_file():
            contents = cached.read_bytes()
            if asset.get('digest') == 'sha256:' + hashlib.sha256(contents).hexdigest():
                previous = json.loads(contents)
                print('Previous update manifest matches the digest published by GitHub.')
    if previous is None:
        previous = json.loads(subprocess.check_output([
            'gh', 'release', 'download', latest['tag_name'], '--repo', 'lincycode/GymMane',
            '--pattern', 'enogym-update.json', '--output', '-',
        ]))
    if manifest['versionCode'] <= previous['versionCode']:
        raise SystemExit('The Android version code must increase for each release.')
    if manifest['signingCertificateSha256'] != previous['signingCertificateSha256']:
        raise SystemExit('The signing certificate differs from the latest published release.')
PY
if gh release view "$GYMMANE_TAG" --repo lincycode/GymMane > /dev/null 2>&1; then
  echo 'This release already exists. Inspect it; do not overwrite a published version.' >&2
  exit 1
fi
git push --set-upstream origin own
gh release create "$GYMMANE_TAG" "$GYMMANE_DIRECTORY"/*.apk "$GYMMANE_DIRECTORY"/*.sha256 \
  "$GYMMANE_DIRECTORY/enogym-update.json" \
  --repo lincycode/GymMane --target "$GYMMANE_COMMIT" --draft \
  --title "EnoGym $GYMMANE_VERSION" --notes-file "$GYMMANE_NOTES"
gh release edit "$GYMMANE_TAG" --repo lincycode/GymMane --draft=false --latest
gh release view "$GYMMANE_TAG" --repo lincycode/GymMane --json url,tagName,isDraft,assets
