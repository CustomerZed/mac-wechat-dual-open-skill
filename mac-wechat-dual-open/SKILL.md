---
name: mac-wechat-dual-open
description: Create a second signed macOS WeChat app for dual login by copying the official WeChat.app into /Applications/WeChat2.app, changing CFBundleIdentifier to com.tencent.xinWeChat2, re-signing it, clearing extended attributes, and validating the result. Use when a user asks to double-open, dual-open, multi-open, or run two Mac WeChat accounts and wants the stable no-plugin /Applications copy method rather than unsafe tweaks or injected helper tools.
---

# Mac WeChat Dual Open

## Overview

Set up a second macOS WeChat app with the same flow that works on recent WeChat 4.x builds: copy the official app into `/Applications`, change the bundle identifier, re-sign with an ad-hoc signature, clear quarantine attributes, and verify before opening.

Prefer this method after simple `open -n` or direct binary launch only brings the existing logged-in WeChat window to the foreground. Avoid third-party plugins, injected tweaks, and modified WeChat distributions unless the user explicitly accepts the account and privacy risk.

## Workflow

1. Check the installed WeChat path. Prefer `/Applications/微信.app`; fall back to `/Applications/WeChat.app`.
2. Create the second app at `/Applications/WeChat2.app`. Do not use a Desktop copy for the primary workflow; recent WeChat builds may open but show "network disconnected" when the signed copy lives outside `/Applications`.
3. Set the main app bundle identifier to `com.tencent.xinWeChat2`.
4. Re-sign the copied app with `codesign --force --deep --sign -`.
5. Clear extended attributes with `xattr -cr`.
6. Validate with `PlistBuddy` and `codesign --verify --deep --strict`.
7. Open `/Applications/WeChat2.app` and have the user confirm it shows a separate QR/login window and can connect.

## Quick Start

Use the bundled script:

```bash
scripts/setup-wechat2.sh --open
```

If `/Applications/WeChat2.app` already exists and the user wants to rebuild it after a WeChat update:

```bash
scripts/setup-wechat2.sh --overwrite --open
```

The script re-execs with `sudo` when it needs to write under `/Applications`; the password prompt is expected and input will not be displayed.

## Manual Commands

Use manual commands when the user wants to see or run each step themselves. Adjust the source path if their app is named `WeChat.app` instead of `微信.app`.

```bash
sudo cp -R /Applications/微信.app /Applications/WeChat2.app
sudo /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.tencent.xinWeChat2" /Applications/WeChat2.app/Contents/Info.plist
sudo codesign --force --deep --sign - /Applications/WeChat2.app
sudo xattr -cr /Applications/WeChat2.app
open /Applications/WeChat2.app
```

## Validation

Run:

```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" /Applications/WeChat2.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=1 /Applications/WeChat2.app
```

Expected:

- Bundle ID prints `com.tencent.xinWeChat2`.
- `codesign` reports `valid on disk` and `satisfies its Designated Requirement`.

## Troubleshooting

- If simple launch commands open the already logged-in WeChat, use the signed `/Applications/WeChat2.app` method.
- If a copied Desktop app shows "network disconnected", rebuild under `/Applications` with administrator privileges and use `com.tencent.xinWeChat2`.
- If macOS says the app is damaged or cannot be verified, run `sudo xattr -cr /Applications/WeChat2.app` and re-open it.
- If WeChat updates and the second app stops working, rebuild the copy from the updated official app.
- If the signed copy still cannot connect, stop and recommend a separate macOS user account instead of escalating to plugins or injected tweaks.

## Safety

Use only the official WeChat app already installed on the Mac. Do not download repackaged WeChat builds. Explain that this is an unofficial workaround and may break after updates.
