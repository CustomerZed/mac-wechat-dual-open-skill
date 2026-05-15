# Mac WeChat Dual Open Skill

Codex skill for setting up a second macOS WeChat app without third-party plugins.

It uses the workflow that worked reliably on recent WeChat 4.x builds:

1. Copy the official WeChat app to `/Applications/WeChat2.app`.
2. Change the copied app's Bundle ID to `com.tencent.xinWeChat2`.
3. Re-sign the copied app with macOS ad-hoc signing.
4. Clear extended attributes.
5. Validate the Bundle ID and code signature.

## Use With Codex

Install or reference the skill folder:

```text
mac-wechat-dual-open/
```

Then ask:

```text
Use $mac-wechat-dual-open to set up a signed WeChat2.app for macOS dual login.
```

## Run The Script Directly

```bash
cd mac-wechat-dual-open
chmod +x scripts/setup-wechat2.sh
scripts/setup-wechat2.sh --open
```

If `/Applications/WeChat2.app` already exists and you want to rebuild it:

```bash
scripts/setup-wechat2.sh --overwrite --open
```

The script may ask for your Mac administrator password because it writes to `/Applications`.

## Notes

- Use only the official WeChat app already installed on your Mac.
- If the source app is named `/Applications/微信.app`, the script auto-detects it.
- If WeChat updates and the second app breaks, rebuild `WeChat2.app`.
- This is an unofficial workaround and may stop working if WeChat changes its checks.
- Avoid plugin/injection-based tools unless you understand the account and privacy risks.

## License

MIT
