# Bonaqu Desktop

**Bonaqu Desktop** is a personal experimental fork of [Telegram Desktop](https://github.com/telegramdesktop/tdesktop), maintained by **bonaqu**.

The fork focuses on Windows x64 testing of Telegram Desktop's new **WEB Proxy** transport while keeping protocol changes as close to upstream as possible.

> **Important:** Bonaqu Desktop is an independent third-party fork. It is not an official Telegram application and is not affiliated with or endorsed by Telegram Messenger Inc. / Telegram FZ-LLC.

## Current baseline

- Recorded upstream baseline: Telegram Desktop **7.1.1** (`61fab838d5fd8e8de8d513fb130ecda4e0cda8b9`).
- Primary target: **Windows x64**.
- WEB Proxy implementation: upstream Telegram Desktop implementation, not a protocol rewrite.
- Temporary API mode: Telegram Desktop **TEST ONLY** credentials via `TDESKTOP_API_TEST=ON` because `my.telegram.org/apps` currently returns a generic `ERROR` when the maintainer attempts to create the first API application.
- Recorded upstream SHA: [`.bonaqu/upstream-base.txt`](.bonaqu/upstream-base.txt).

Telegram documents the TEST ONLY credentials as heavily limited and unsuitable for deployment. A normal distributable build must use a dedicated `api_id` and `api_hash` when Telegram API Development Tools allows the application to be registered.

## Project URL

Project page: **https://bonaqu.github.io/tdesktop-bonaqu/**

Repository: **https://github.com/bonaqu/tdesktop-bonaqu**

## WEB Proxy

Current Telegram Desktop development sources contain the WEB Proxy connection type and the WebView-based MTProto carrier. The external WEB Proxy HTTPS connection is made through the platform WebView/browser carrier while Telegram's existing MTProxy protocol layer handles the opaque MTProto bytes.

The feature is new and remains experimental until the upstream P0/P1 test plan has been exercised against a compatible hosted relay.

## Windows x64 test build

The fork contains `.github/workflows/bonaqu-win64.yml`, a focused Windows x64 Release workflow instead of Telegram's complete architecture/platform build matrix.

It uses:

```text
-D TDESKTOP_API_TEST=ON
-D DESKTOP_APP_DISABLE_AUTOUPDATE=ON
-D DESKTOP_APP_DISABLE_CRASH_REPORTS=ON
```

The artifact contains:

- `BonaquDesktop.exe`;
- `Start-Bonaqu-Desktop.cmd` — normal isolated launch;
- `Start-Bonaqu-Desktop-Debug.cmd` — isolated launch with Telegram debug logging;
- `BUILD-INFO.txt` — source commit and build mode;
- `SHA256SUMS.txt` — SHA-256 of the executable.

Use the launcher script rather than double-clicking the executable while this build is experimental. The script starts the client with `-workdir <artifact>\BonaquProfile`, keeping its profile separate from normal Telegram Desktop `tdata`.

No private Telegram API secret is committed to this repository.

## Testing

Start with [`docs/bonaqu-testing.md`](docs/bonaqu-testing.md). It contains the Bonaqu smoke-test procedure, isolated-profile rules, diagnostic collection and a summary of the wider upstream WEB Proxy test requirements.

The upstream source of truth is [`docs/web-proxy-test-plan.md`](docs/web-proxy-test-plan.md). A successful compile is not evidence that every WEB Proxy runtime case is correct.

## Upstream maintenance

Bonaqu-specific changes should remain small and isolated. Upstream security fixes, crash fixes and WEB Proxy fixes take priority over local customization.

`.github/workflows/bonaqu-upstream-check.yml` checks Telegram Desktop's `dev` head weekly and reports when it differs from `.bonaqu/upstream-base.txt`. Upstream changes should be reviewed and rebuilt deliberately rather than blindly auto-merged into a network-transport experiment.

The pre-7.1.1 Bonaqu `dev` state is preserved in the `backup-dev-before-7.1.1` branch.

## References

- Telegram Desktop upstream: https://github.com/telegramdesktop/tdesktop
- WEB Proxy server PoC: https://github.com/telegramdesktop/tproxy-server
- Telegram API documentation: https://core.telegram.org/api
- Telegram Desktop API credential notes: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/api_credentials.md
- Windows build instructions: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/building-win.md
- WEB Proxy client test plan: `docs/web-proxy-test-plan.md`

## License and attribution

Bonaqu Desktop is derived from Telegram Desktop. The upstream source is published under GPLv3 with the OpenSSL exception. See [LICENSE](LICENSE) and [LEGAL](LEGAL) for the applicable license and attribution information.

Upstream copyright and third-party notices remain the property of their respective owners.
