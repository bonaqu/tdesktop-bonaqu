# Bonaqu Desktop

**Bonaqu Desktop** is a personal experimental fork of [Telegram Desktop](https://github.com/telegramdesktop/tdesktop), maintained by **bonaqu**.

The fork tracks Telegram Desktop's current `dev` sources and focuses on Windows x64 testing of the new **WEB Proxy** transport while keeping the codebase as close to upstream as possible.

> **Important:** Bonaqu Desktop is an independent third-party fork. It is not an official Telegram application and is not affiliated with or endorsed by Telegram Messenger Inc. / Telegram FZ-LLC.

## Current baseline

- Upstream baseline: Telegram Desktop **7.1.1** (`61fab838d5fd8e8de8d513fb130ecda4e0cda8b9`).
- Primary target: **Windows x64**.
- WEB Proxy implementation: upstream Telegram Desktop implementation, not a protocol rewrite.
- Temporary API mode: official Telegram Desktop **test-only API credentials** via `TDESKTOP_API_TEST=ON` while `my.telegram.org/apps` is failing to create a new API application for the maintainer.

The test API mode is intended only for development/testing. A distributable build should use a dedicated `api_id` and `api_hash` as soon as Telegram API Development Tools allows the application to be registered.

## Project URL

Project page: **https://bonaqu.github.io/tdesktop-bonaqu/**

Repository: **https://github.com/bonaqu/tdesktop-bonaqu**

## WEB Proxy

Current Telegram Desktop development sources contain the WEB Proxy connection type and the WebView-based MTProto carrier. The design keeps the external WEB Proxy HTTPS connection inside the platform WebView/browser carrier while Telegram's existing MTProxy protocol layer handles the opaque MTProto bytes.

The feature is new and should still be treated as experimental until its upstream P0/P1 test plan has been exercised against a compatible hosted relay.

## Bonaqu Windows build

The fork contains a focused GitHub Actions workflow for a Windows x64 test build. It deliberately builds only the target needed for Bonaqu Desktop instead of Telegram's full x86/x64/ARM and Qt matrix.

The workflow uses:

```text
-D TDESKTOP_API_TEST=ON
```

No private Telegram API secret is committed to this repository.

## Upstream sync policy

Bonaqu-specific changes should remain small and isolated. Upstream security fixes, crash fixes and WEB Proxy fixes take priority over local customization. The fork should be rebased/refreshed onto the newest upstream `dev` baseline before adding substantial features.

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
