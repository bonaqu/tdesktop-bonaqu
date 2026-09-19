# Bonaqu Client roadmap

This document is the implementation map for Bonaqu-specific work. Substantial features should land through separate branches / pull requests, compile in Windows x64 PR CI, and follow `.bonaqu/features.json` plus `docs/upstream-sync-policy.md`.

## P0 — fork foundation

- [x] Independent Windows application / installer / runtime identity.
- [x] Personal Telegram API credentials through Actions Secrets for distributable builds.
- [x] Isolated default profile.
- [x] Multi-profile launcher / profile manager.
- [x] WEB Proxy development integration retained.
- [x] Daily upstream lifecycle tracking and supersession policy.
- [x] Machine-readable feature lifecycle registry.
- [x] Safe Windows x64 PR compile CI without personal API Secrets or PR binaries.

## P1 — Bonaqu Control Center

- [ ] Merge the first Control Center PR after Windows x64 PR compilation passes.
- [ ] Privacy-safe copyable connection diagnostics.
- [ ] WEB Proxy / SOCKS5 / HTTP / MTProto mode summary.
- [ ] Quick open of the Bonaqu data directory.
- [ ] In-client links to Bonaqu source / feature policy.
- [ ] Move the tools from About into a dedicated Settings section after the first slice proves stable.
- [ ] Add one-click diagnostic export that redacts credentials, account identifiers and absolute local paths.
- [ ] Add a profile-manager entry point inside the client.

## P2 — downloads and media power tools

Design rule: extend Telegram Desktop's existing Downloads implementation instead of replacing it.

- [ ] Inspect current upstream Downloads APIs and model ownership.
- [ ] Filters: active / finished / failed / media / files.
- [ ] Pause/resume all where the underlying operation supports it.
- [ ] Retry failed downloads.
- [ ] Clear completed entries without touching downloaded files.
- [ ] Quick actions: open file / show in folder / copy local path.
- [ ] Optional per-chat download grouping when it can remain additive to upstream.
- [ ] Better progress/status detail without exposing private internals.

## P3 — power-user actions and shortcuts

- [ ] Inventory the upstream shortcut/action registry before adding bindings.
- [ ] Bonaqu-only quick actions with conflict detection.
- [ ] Fast open: Downloads, Saved Messages, proxy settings and profile switcher.
- [ ] Copy current chat/message link where Telegram provides a valid link.
- [ ] Toggle compact/visual preferences through actions.
- [ ] Consider a searchable command palette only if it can reuse upstream actions rather than duplicate them.

## P4 — visual identity and UX polish

Design rule: build on Telegram Desktop theme/style APIs; do not fork the renderer.

- [ ] Bonaqu icon set that is visually distinct from official Telegram.
- [ ] Bonaqu accent presets using upstream theming capabilities.
- [ ] Consistent Bonaqu branding in About / Settings / Windows metadata / shortcuts.
- [ ] Compact density option where upstream layout primitives allow it safely.
- [ ] Review spacing and discoverability of advanced settings.
- [ ] Avoid redesign churn that increases merge conflicts without improving usability.

## P5 — local voice transcription

This is a local/offline alternative, not a spoof of Telegram Premium entitlement.

- [ ] Architecture and licensing review before code.
- [ ] Evaluate an embeddable open speech-to-text model/runtime suitable for redistribution.
- [ ] Optional model download; do not bloat the base installer.
- [ ] Local-only processing mode with a clear privacy indicator.
- [ ] CPU path first; optional hardware acceleration only when maintainable on Windows.
- [ ] Language selection / auto-detection.
- [ ] Copy transcript and searchable transcript UI.
- [ ] Graceful handling of long audio, unsupported codecs and missing models.
- [ ] Never send a fake Premium/server-transcription state to Telegram.

## P6 — integrated profile experience

- [ ] Bring the existing profile manager into the application UI.
- [ ] Create / rename / open local Bonaqu profiles safely.
- [ ] Show the active workdir/profile without revealing full paths by default.
- [ ] Parallel launch through supported multi-instance/workdir mechanisms.
- [ ] Migration path if Telegram later ships equivalent first-class profile management.

## P7 — reliability and update lifecycle

- [x] Track Telegram Desktop `dev` every day for drift.
- [ ] Keep stable Telegram Desktop releases as the default Bonaqu update baseline.
- [ ] Review `upstream/dev` for security, protocol, account/login, crash and data-integrity fixes.
- [ ] Cherry-pick critical reviewed fixes when waiting for the next stable release is unreasonable.
- [ ] Run Windows x64 compile + Bonaqu smoke/regression checks for every upstream sync.
- [ ] Update `.bonaqu/upstream-base.txt` only after the sync is accepted.
- [ ] For every overlapping Telegram feature: prefer upstream core behaviour, migrate settings, keep only Bonaqu's additive value, then mark the old implementation `upstreamed` / remove dead duplicate code.

## Feature acceptance rules

A Bonaqu feature is not complete merely because code exists. Before marking it `active`, it should, where applicable:

1. compile in Windows x64 CI;
2. avoid changing Telegram protocol semantics unless required by upstream;
3. avoid spoofing server-side entitlements;
4. avoid leaking credentials or account data in diagnostics;
5. have an entry and supersession rule in `.bonaqu/features.json`;
6. survive upstream updates or have an explicit migration strategy;
7. add observable user value rather than branding-only churn.

## When Telegram reaches feature parity

If Telegram Desktop later ships the same function, Bonaqu does not keep a second implementation by default. Compare both implementations, adopt upstream for protocol/account-facing behaviour, migrate Bonaqu settings where practical, retain only genuinely additive Bonaqu UX, and delete obsolete duplicate code after the compatibility window described in `docs/upstream-sync-policy.md`.
