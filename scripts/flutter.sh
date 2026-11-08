#!/usr/bin/env bash
set -euo pipefail
GYMMANE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$GYMMANE_ROOT/.toolchain/env.sh" ]]; then
  source "$GYMMANE_ROOT/.toolchain/env.sh"
fi
GYMMANE_FLUTTER="${GYMMANE_FLUTTER:-$GYMMANE_ROOT/.toolchain/flutter/bin/flutter}"
if [[ ! -x "$GYMMANE_FLUTTER" ]]; then
  echo 'Flutter 3.41.9 is required. See docs/OWN.md.' >&2
  exit 1
fi
export PUB_CACHE="${GYMMANE_PUB_CACHE:-$GYMMANE_ROOT/.toolchain/pub-cache}"
export GRADLE_USER_HOME="${GYMMANE_GRADLE_HOME:-$GYMMANE_ROOT/.toolchain/gradle-home}"
export ANDROID_USER_HOME="$GYMMANE_ROOT/.toolchain/android-user"
export ANDROID_AVD_HOME="$GYMMANE_ROOT/.toolchain/avd"
export FLUTTER_SUPPRESS_ANALYTICS=true
exec "$GYMMANE_FLUTTER" --no-version-check "$@"
