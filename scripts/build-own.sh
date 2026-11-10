#!/usr/bin/env bash
set -euo pipefail
GYMMANE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$GYMMANE_ROOT"
GYMMANE_MODE="${1:-release}"
if [[ "$GYMMANE_MODE" != release && "$GYMMANE_MODE" != debug ]] ||
   [[ "$#" -gt 2 || ( "$#" -eq 2 && "$2" != --no-pub ) ]]; then
  echo 'Usage: bash scripts/build-own.sh [release|debug] [--no-pub]' >&2
  exit 1
fi
GYMMANE_VERSION="$(sed -n 's/^versionName=//p' own.properties)"
GYMMANE_BUILD="$(sed -n 's/^versionCode=//p' own.properties)"
GYMMANE_FLUTTER_VERSION="$(sed -n 's/^flutterVersion=//p' own.properties)"
mkdir -p .toolchain
bash scripts/flutter.sh --version --machine > .toolchain/flutter-version.json
python3 - "$GYMMANE_FLUTTER_VERSION" <<'PY'
import json, sys
actual = json.load(open('.toolchain/flutter-version.json'))['frameworkVersion']
if actual != sys.argv[1]:
    raise SystemExit(f'Expected Flutter {sys.argv[1]}, found {actual}')
PY
GYMMANE_PUB_ARGS=(--enforce-lockfile)
if [[ "${GYMMANE_OFFLINE:-0}" == 1 ]]; then
  GYMMANE_PUB_ARGS+=(--offline)
fi
if [[ "${2:-}" != --no-pub ]]; then
  bash scripts/flutter.sh pub get "${GYMMANE_PUB_ARGS[@]}"
fi
bash scripts/flutter.sh build apk "--$GYMMANE_MODE" --no-pub --split-per-abi \
  --target-platform android-arm64 \
  --build-name "$GYMMANE_VERSION" --build-number "$GYMMANE_BUILD" \
  --dart-define="OWN_VERSION=$GYMMANE_VERSION"
mkdir -p artifacts/apk
GYMMANE_APK="artifacts/apk/EnoGym-$GYMMANE_VERSION-Ace6T-arm64-v8a-$GYMMANE_MODE.apk"
cp "build/app/outputs/flutter-apk/app-arm64-v8a-$GYMMANE_MODE.apk" "$GYMMANE_APK"
shasum -a 256 "$GYMMANE_APK"
