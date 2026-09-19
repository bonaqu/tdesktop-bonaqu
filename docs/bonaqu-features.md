# Bonaqu Client feature policy and roadmap

Bonaqu Client is an unofficial Telegram client derived from Telegram Desktop. The goal is to keep Telegram compatibility and upstream behavior while adding useful local Windows and power-user features.

## Implemented

### Independent Windows identity

- Product name: `Bonaqu Client`.
- Packaged executable: `BonaquClient.exe`.
- Independent installer AppId.
- Independent runtime/IPC GUID.
- Independent installed data directory (`%APPDATA%\Bonaqu Client`).
- Portable builds use an explicit isolated `BonaquProfile` work directory.

### Personal Telegram API application

GitHub Actions builds require the maintainer's own API application credentials through repository secrets:

- `BONAQU_TDESKTOP_API_ID`;
- `BONAQU_TDESKTOP_API_HASH`.

The current Telegram API application metadata recorded for the fork is:

- title: `BonaquDesktop26`;
- short name: `bonaqu26`.

Credentials must not be committed to the source repository or intentionally printed in build logs. They are compiled into Telegram Desktop-based client binaries and therefore must be treated as recoverable from distributed executables.

### Bonaqu Profile Manager

`Bonaqu-Profile-Manager.ps1` and `Bonaqu-Profiles.cmd` provide a simple local profile launcher.

Each named profile gets its own `Profiles\<name>` work directory and is launched using Telegram Desktop's `-many` and `-workdir` command-line switches. This provides a convenient local analogue to advanced multi-account workflows without modifying Telegram account entitlements.

### WEB Proxy

The fork retains the WEB Proxy implementation present in the selected Telegram Desktop upstream baseline and the accompanying test plans.

### Experimental-build safety

- automatic Telegram Desktop updater disabled;
- upstream crash reporting disabled;
- isolated launch scripts;
- build SHA-256 included in artifacts;
- debug launcher kept separate from normal launch.

## Planned local enhancements

These are suitable Bonaqu Client directions because they can be implemented locally without pretending a Telegram account owns server-side Premium capabilities:

- a dedicated Bonaqu settings section;
- additional accent/theme presets and clearer visual differentiation from official Telegram Desktop;
- power-user quick actions and configurable shortcuts;
- richer download rules and download-management shortcuts;
- optional local voice-message transcription where technically practical;
- better profile-management UI integrated into the application;
- diagnostic helpers for WEB Proxy and connection state;
- optional compact/comfortable layout presets that remain compatible with upstream UI behavior.

Planned items are not considered implemented until they exist in source and pass a build/runtime test.

## Premium and server-side boundaries

Bonaqu Client does not fake Telegram Premium state and does not bypass Telegram server-side entitlements. Examples include:

- Premium account badges or entitlement flags;
- Premium-only server limits;
- account upload-size limits controlled by Telegram;
- Premium reactions or other server-authorized capabilities;
- server-side limits on folders, channels, pinned chats or similar resources.

A client-side UI patch cannot legitimately grant these server-side permissions to an account that does not have them.

Local alternatives are allowed where they do not misrepresent account state or violate Telegram API requirements. The Profile Manager is one example: it improves local workflow while leaving Telegram account permissions untouched.

## Compatibility policy

Bonaqu-specific changes should remain small enough to review against upstream Telegram Desktop. Security, protocol and WEB Proxy fixes from upstream take precedence over cosmetic customization.

Features that intentionally break expected Telegram semantics or API requirements are out of scope. In particular, the project should not add hidden read-status suppression, hidden typing/online activity, sponsored-message interference, self-destruct bypasses, or similar behavior that changes required Telegram service semantics.
