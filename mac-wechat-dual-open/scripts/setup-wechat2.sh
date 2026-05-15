#!/bin/zsh
set -euo pipefail

SOURCE_APP=""
TARGET_APP="/Applications/WeChat2.app"
BUNDLE_ID="com.tencent.xinWeChat2"
OPEN_AFTER=false
OVERWRITE=false
ORIGINAL_ARGS=("$@")
SCRIPT_PATH="${0:A}"

usage() {
  cat <<'EOF'
Usage: setup-wechat2.sh [options]

Create a signed second macOS WeChat app at /Applications/WeChat2.app.

Options:
  --source PATH      Source WeChat.app path. Auto-detects /Applications/微信.app or /Applications/WeChat.app.
  --target PATH      Target .app path. Default: /Applications/WeChat2.app
  --bundle-id ID     Bundle identifier for the copy. Default: com.tencent.xinWeChat2
  --overwrite        Replace the target app if it already exists.
  --open             Open the copied app after validation.
  -h, --help         Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_APP="${2:-}"
      shift 2
      ;;
    --target)
      TARGET_APP="${2:-}"
      shift 2
      ;;
    --bundle-id)
      BUNDLE_ID="${2:-}"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=true
      shift
      ;;
    --open)
      OPEN_AFTER=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SOURCE_APP" ]]; then
  for candidate in "/Applications/微信.app" "/Applications/WeChat.app"; do
    if [[ -d "$candidate" ]]; then
      SOURCE_APP="$candidate"
      break
    fi
  done
fi

if [[ -z "$SOURCE_APP" || ! -d "$SOURCE_APP" ]]; then
  echo "Could not find WeChat. Use --source /Applications/微信.app or --source /Applications/WeChat.app." >&2
  exit 1
fi

if [[ "$SOURCE_APP" == "$TARGET_APP" ]]; then
  echo "Source and target must be different paths." >&2
  exit 1
fi

if [[ "$TARGET_APP" != *.app ]]; then
  echo "Target must end with .app: $TARGET_APP" >&2
  exit 1
fi

if [[ "$TARGET_APP" != /Applications/* ]]; then
  echo "Warning: recent WeChat builds are more reliable when the copy lives under /Applications." >&2
fi

if [[ "$EUID" -ne 0 && "$TARGET_APP" == /Applications/* ]]; then
  echo "Administrator privileges are required to write $TARGET_APP."
  exec sudo "$SCRIPT_PATH" "${ORIGINAL_ARGS[@]}"
fi

if [[ -e "$TARGET_APP" ]]; then
  if [[ "$OVERWRITE" != true ]]; then
    echo "Target already exists: $TARGET_APP" >&2
    echo "Re-run with --overwrite to replace it." >&2
    exit 1
  fi
  rm -rf "$TARGET_APP"
fi

echo "Copying $SOURCE_APP -> $TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "Setting bundle identifier: $BUNDLE_ID"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$TARGET_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName WeChat2" "$TARGET_APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName WeChat2" "$TARGET_APP/Contents/Info.plist" 2>/dev/null || true

echo "Re-signing app"
codesign --force --deep --sign - "$TARGET_APP"

echo "Clearing extended attributes"
xattr -cr "$TARGET_APP" || true

echo "Validating bundle identifier"
actual_id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$TARGET_APP/Contents/Info.plist")"
if [[ "$actual_id" != "$BUNDLE_ID" ]]; then
  echo "Bundle ID mismatch: expected $BUNDLE_ID, got $actual_id" >&2
  exit 1
fi

echo "Validating signature"
codesign --verify --deep --strict --verbose=1 "$TARGET_APP"

echo "Done: $TARGET_APP"
if [[ "$OPEN_AFTER" == true ]]; then
  open "$TARGET_APP"
fi
