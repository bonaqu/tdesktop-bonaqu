# Bonaqu Desktop

**Bonaqu Desktop** is a personal experimental fork of [Telegram Desktop](https://github.com/telegramdesktop/tdesktop), maintained by **bonaqu**.

The project tracks Telegram Desktop's `dev` branch and is currently intended for testing the new **WEB Proxy** transport and related Telegram Desktop changes before they reach a regular stable release.

> **Important:** Bonaqu Desktop is an independent third-party fork. It is not an official Telegram application and is not affiliated with or endorsed by Telegram Messenger Inc. / Telegram FZ-LLC.

## Project URL

Canonical project page:

**https://github.com/bonaqu/tdesktop-bonaqu**

This public HTTPS URL may be used as the application/project URL when registering Bonaqu Desktop in Telegram API Development Tools at `my.telegram.org/apps`.

## Current focus

- Windows x64 builds based on current Telegram Desktop sources.
- Testing Telegram Desktop's new WEB Proxy connection type.
- Keeping the fork close to upstream so future Telegram Desktop updates can be incorporated with minimal divergence.
- Using a separate Telegram API application (`api_id` / `api_hash`) for Bonaqu Desktop builds rather than Telegram Desktop's test-only credentials.

## WEB Proxy

Recent Telegram Desktop `dev` sources include the new WEB Proxy type in connection settings and the related WebView-based MTProto transport implementation. Bonaqu Desktop follows that upstream implementation rather than reimplementing the protocol from scratch.

The WEB Proxy feature is experimental and may change as upstream Telegram Desktop development continues.

## Upstream

Original project:

- Telegram Desktop: https://github.com/telegramdesktop/tdesktop
- Telegram API documentation: https://core.telegram.org/api
- Telegram MTProto documentation: https://core.telegram.org/mtproto

## Building

Telegram Desktop requires your own Telegram API credentials for non-test builds. Official upstream instructions are available here:

- API credentials: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/api_credentials.md
- Windows build instructions: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/building-win.md

Do **not** publish an `api_hash` in the repository. Build credentials should be stored outside tracked source files, for example as repository secrets when using GitHub Actions.

## License and attribution

Bonaqu Desktop is derived from Telegram Desktop. The upstream source is published under GPLv3 with the OpenSSL exception. See [LICENSE](LICENSE) and [LEGAL](LEGAL) in this repository for the applicable license and attribution information.

Upstream copyright and third-party notices remain the property of their respective owners.
