# Bonaqu Client

**Bonaqu Client** is a personal experimental **unofficial Telegram client** derived from [Telegram Desktop](https://github.com/telegramdesktop/tdesktop) and maintained by **bonaqu**.

It keeps Telegram Desktop's protocol implementation and core UX close to upstream while adding Bonaqu-specific Windows identity, isolated profiles, WEB Proxy testing support and selected local power-user features.

> **Important:** Bonaqu Client is an independent third-party client that uses the Telegram API. It is not an official Telegram application and is not affiliated with or endorsed by Telegram Messenger Inc. / Telegram FZ-LLC.

## Current baseline

- Recorded upstream baseline: Telegram Desktop **7.1.1** (`61fab838d5fd8e8de8d513fb130ecda4e0cda8b9`).
- Primary target: **Windows x64**.
- Telegram API application title: **BonaquDesktop26**.
- Telegram API application short name: **bonaqu26**.
- Builds use the maintainer's own `api_id` and `api_hash` through GitHub Actions Secrets; TEST ONLY credentials are no longer used.
- WEB Proxy implementation: upstream Telegram Desktop implementation, not a protocol rewrite.
- Recorded upstream SHA: [`.bonaqu/upstream-base.txt`](.bonaqu/upstream-base.txt).

## Independent Windows identity

Bonaqu Client is intentionally separated from an installed copy of official Telegram Desktop:

- product/application name: `Bonaqu Client`;
- executable in packaged builds: `BonaquClient.exe`;
- independent Windows installer AppId;
- independent runtime/IPC GUID;
- installer data directory: `%APPDATA%\Bonaqu Client`;
- portable builds launch with their own `BonaquProfile` working directory;
- Windows executable metadata identifies the product as Bonaqu Client.

This allows Bonaqu Client and official Telegram Desktop to coexist without deliberately sharing the same local `tdata` profile or installer identity.

## Features

Currently implemented Bonaqu-specific functionality includes:

- **WEB Proxy** support inherited from the current Telegram Desktop development implementation;
- **isolated portable profile** launcher;
- **Bonaqu Profile Manager** for creating and launching multiple independent local profiles with separate work directories;
- dedicated Windows application/installer/runtime identity;
- Bonaqu-branded About dialog with upstream attribution and source link;
- Release build with automatic upstream Telegram updates disabled so the fork does not accidentally replace itself with an official build;
- crash reporting disabled in the experimental build;
- explicit build progress and dependency-cache handling in GitHub Actions.

See [`docs/bonaqu-features.md`](docs/bonaqu-features.md) for the feature policy and roadmap.

## Premium-like features: project policy

Bonaqu Client may add **local alternatives** to convenience features, for example multi-profile tools, local processing, extra themes, quick actions and download-management improvements.

It does **not** pretend that a non-Premium Telegram account is Premium and does not bypass Telegram server-side entitlements such as server limits, Premium reactions, Premium upload limits or other account-level capabilities. Those are controlled by Telegram's servers, not merely by the desktop UI.

The fork also avoids behavior that breaks Telegram API requirements for third-party clients, including intentionally suppressing read/online/typing status or interfering with required Telegram functionality.

## Project URL

Project page: **https://bonaqu.github.io/tdesktop-bonaqu/**

Repository: **https://github.com/bonaqu/tdesktop-bonaqu**

## WEB Proxy

Current Telegram Desktop development sources contain the WEB Proxy connection type and the WebView-based MTProto carrier. The external WEB Proxy HTTPS connection is made through the platform WebView/browser carrier while Telegram's existing MTProxy protocol layer handles the opaque MTProto bytes.

The feature remains experimental until the upstream P0/P1 test plan has been exercised against a compatible hosted relay.

## Windows x64 build

The fork contains `.github/workflows/bonaqu-win64.yml`, a focused Windows x64 Release workflow instead of Telegram's complete architecture/platform build matrix.

The configure stage uses the repository secrets:

```text
TDESKTOP_API_ID    <- BONAQU_TDESKTOP_API_ID
TDESKTOP_API_HASH  <- BONAQU_TDESKTOP_API_HASH
```

and also builds with:

```text
-D DESKTOP_APP_DISABLE_AUTOUPDATE=ON
-D DESKTOP_APP_DISABLE_CRASH_REPORTS=ON
```

### Required GitHub Actions Secrets

The repository must contain these two Actions secrets before the workflow can build:

- `BONAQU_TDESKTOP_API_ID` — numeric App api_id from `my.telegram.org/apps`;
- `BONAQU_TDESKTOP_API_HASH` — App api_hash from `my.telegram.org/apps`.

Do not commit either value into source files. The workflow does not intentionally print them. Telegram Desktop does compile API credentials into the client binary, so credentials contained in a distributed executable must be considered recoverable by somebody inspecting that binary.

### Artifact contents

The build artifact contains:

- `BonaquClient.exe`;
- `Start-Bonaqu-Client.cmd` — normal isolated launch;
- `Start-Bonaqu-Client-Debug.cmd` — isolated launch with debug logging;
- `Bonaqu-Profiles.cmd` — interactive multi-profile launcher;
- `Bonaqu-Profile-Manager.ps1` — profile manager implementation;
- `BUILD-INFO.txt` — source commit and build mode;
- `SHA256SUMS.txt` — SHA-256 of the executable.

The normal launcher starts the client with `-workdir <artifact>\BonaquProfile`, keeping its profile separate from normal Telegram Desktop `tdata`. The Profile Manager uses a separate `Profiles\<name>` directory for every profile and starts them with `-many` plus an explicit `-workdir`.

## Testing

Start with [`docs/bonaqu-testing.md`](docs/bonaqu-testing.md). It contains the Bonaqu smoke-test procedure, isolated-profile rules, diagnostic collection and a summary of the wider upstream WEB Proxy test requirements.

The upstream source of truth for WEB Proxy testing is [`docs/web-proxy-test-plan.md`](docs/web-proxy-test-plan.md). A successful compile is not evidence that every WEB Proxy runtime case is correct.

## Upstream maintenance

Bonaqu-specific changes should remain isolated and reviewable. Upstream security fixes, crash fixes and WEB Proxy fixes take priority over local customization.

`.github/workflows/bonaqu-upstream-check.yml` checks Telegram Desktop's `dev` head weekly and reports when it differs from `.bonaqu/upstream-base.txt`. Upstream changes should be reviewed and rebuilt deliberately rather than blindly auto-merged into a network-transport experiment.

The pre-7.1.1 Bonaqu `dev` state is preserved in the `backup-dev-before-7.1.1` branch.

## References

- Telegram Desktop upstream: https://github.com/telegramdesktop/tdesktop
- WEB Proxy server PoC: https://github.com/telegramdesktop/tproxy-server
- Telegram API documentation: https://core.telegram.org/api
- Telegram API Terms of Service: https://core.telegram.org/api/terms
- Telegram Desktop API credential notes: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/api_credentials.md
- Windows build instructions: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/building-win.md
- WEB Proxy client test plan: `docs/web-proxy-test-plan.md`

## License and attribution

Bonaqu Client is derived from Telegram Desktop. The upstream source is published under GPLv3 with the OpenSSL exception. See [LICENSE](LICENSE) and [LEGAL](LEGAL) for the applicable license and attribution information.

Upstream copyright and third-party notices remain the property of their respective owners.
