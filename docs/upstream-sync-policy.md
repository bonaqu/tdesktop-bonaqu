# Bonaqu Client upstream sync policy

Bonaqu Client is an additive fork of Telegram Desktop. The goal is to keep the client recognisably compatible with upstream while making local UX and power-user improvements easy to maintain.

## Source of truth

- Upstream repository: `telegramdesktop/tdesktop`.
- Recorded base commit: `.bonaqu/upstream-base.txt`.
- Default update target: the newest stable Telegram Desktop release that has been reviewed and built successfully in Bonaqu Client.
- `upstream/dev` is watched continuously for fixes and upcoming conflicts, but it is not blindly auto-merged into the distributable branch.

Security fixes, account/login fixes, protocol compatibility fixes and crash/data-loss fixes may be cherry-picked from `upstream/dev` before the next stable release when the change is understood and passes the Bonaqu regression suite.

## Update flow

1. The scheduled upstream workflow compares `.bonaqu/upstream-base.txt` with Telegram Desktop `dev` and reports drift.
2. When a new stable release or an important upstream fix appears, create a dedicated `upstream/<version-or-sha>` branch from `dev`.
3. Import upstream changes without rewriting Bonaqu commits unless conflict resolution requires it.
4. Resolve conflicts by preserving upstream protocol/security behaviour first, then re-applying Bonaqu-specific UX on top.
5. Build Windows x64 with the personal Telegram API credentials from GitHub Actions Secrets.
6. Run the Bonaqu smoke/regression checklist, including login, chats, media, calls where available, updates disabled, isolated profile behaviour and WEB Proxy tests.
7. Update `.bonaqu/upstream-base.txt` only after the reviewed upstream sync is accepted.
8. Merge the upstream PR before starting feature work that depends on changed upstream code.

## What happens when Telegram ships a Bonaqu feature

Every Bonaqu feature has a lifecycle entry in `.bonaqu/features.json`.

When upstream introduces overlapping functionality:

1. Compare behaviour, storage format, shortcuts, UI and edge cases.
2. Prefer the upstream implementation for protocol-facing or account-facing behaviour.
3. If upstream fully replaces the Bonaqu implementation, mark the Bonaqu feature `upstreamed` and remove duplicated code after migration/testing.
4. If Bonaqu still adds useful local behaviour, keep only the additive layer and make it call or extend the upstream implementation rather than maintaining a second copy.
5. Preserve user settings where practical. When a setting changes format, add one-way migration and document it in the PR.
6. Keep a compatibility shim for at most one stable upstream release when removing it immediately could break stored Bonaqu settings or profiles.
7. Remove dead toggles, duplicate menu items and duplicate translations once migration is complete.

The objective is not to win a feature-count contest with upstream. If Telegram implements something better, Bonaqu adopts it and spends maintenance budget on the parts that remain uniquely useful.

## Conflict priority

When an upstream sync conflicts with Bonaqu code, resolve in this order:

1. account/session safety and data integrity;
2. Telegram protocol/API compatibility;
3. security/privacy fixes;
4. crash fixes and platform compatibility;
5. Bonaqu profile isolation and application identity;
6. Bonaqu feature behaviour;
7. visual polish.

## Feature design rules

New Bonaqu features should be:

- local/additive where possible;
- isolated in small files or clearly delimited sections;
- switchable when they materially change upstream behaviour;
- independent of Telegram Premium entitlement unless the server explicitly permits the operation for the account;
- documented in `.bonaqu/features.json` with an upstream supersession rule;
- covered by at least one build-time or smoke-test check when practical.

Avoid patching scattered `isPremium()` checks or changing MTProto semantics to imitate server-granted entitlements. Local alternatives (for example local transcription, better profile handling, extra shortcuts or richer download tools) are preferred because they remain maintainable and honest about what the server actually grants.
