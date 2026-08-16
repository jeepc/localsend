#!/bin/bash
# Builds LocalSend.app for macOS with ad-hoc signing (no certificate / Apple account needed).
#
# Step 3 exists because this fork signs ad-hoc: LaunchAtLogin-Legacy's copy-helper-swiftpm.sh
# rewrites the helper's CFBundleIdentifier and then re-signs it with $EXPANDED_CODE_SIGN_IDENTITY_NAME,
# which Xcode leaves empty when CODE_SIGN_IDENTITY is "-". That codesign call fails with
# "no identity found", the script has no `set -e`, so the build "succeeds" with a helper whose
# signature no longer matches its Info.plist. Signing a real certificate would make step 3 unnecessary.
#
# Usage:
#   support/scripts/build-macos.sh              # pub get + build + re-sign
#   support/scripts/build-macos.sh --no-pub-get # skip dependency refresh
#   support/scripts/build-macos.sh --clean      # flutter clean first

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$REPO_ROOT/app"
APP="$APP_DIR/build/macos/Build/Products/Release/LocalSend.app"
HELPER="$APP/Contents/Library/LoginItems/LaunchAtLoginHelper.app"

PUB_GET=1
CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --no-pub-get) PUB_GET=0 ;;
    --clean) CLEAN=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# 1. Dependencies
if [[ $CLEAN == 1 ]]; then
  echo "==> flutter clean"
  (cd "$APP_DIR" && fvm flutter clean)
fi

if [[ $PUB_GET == 1 ]]; then
  echo "==> pub get"
  (cd "$APP_DIR" && fvm flutter pub get)
  (cd "$REPO_ROOT/packages/localsend_isolates" && fvm flutter pub get)
fi

# 2. Build
echo "==> flutter build macos"
(cd "$APP_DIR" && fvm flutter build macos)

[[ -d "$APP" ]] || { echo "Build finished but $APP is missing" >&2; exit 1; }

# 3. Re-sign ad-hoc, inside out
echo "==> re-signing ad-hoc"
ENTITLEMENTS="$(mktemp -t localsend-entitlements)"
trap 'rm -f "$ENTITLEMENTS"' EXIT
codesign -d --entitlements :- --xml "$APP" > "$ENTITLEMENTS" 2>/dev/null
[[ -s "$ENTITLEMENTS" ]] || { echo "Could not read entitlements from $APP" >&2; exit 1; }

if [[ -d "$HELPER" ]]; then
  codesign --force --sign - "$HELPER"
fi
codesign --force --sign - --entitlements "$ENTITLEMENTS" "$APP"

# Verify — a broken nested signature is exactly the failure this script exists to prevent,
# so treat it as fatal rather than letting a bad bundle through.
echo "==> verifying"
codesign --verify --deep --strict "$APP"

echo
echo "Built and signed: $APP"
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E "^(Identifier|Signature|Format)"
