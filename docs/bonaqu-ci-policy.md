# Bonaqu Client CI policy

Bonaqu Client owns its fork CI instead of inheriting Telegram Desktop's complete platform matrix on every feature pull request.

## Automatic checks

- `.github/workflows/bonaqu-win64.yml` is the primary compile gate for Bonaqu feature PRs.
- Pull requests compile Windows x64 with Telegram Desktop TEST ONLY API credentials and publish no client artifact.
- `dev` / manually dispatched distributable builds use the repository's personal Bonaqu API Secrets and may publish the Windows x64 artifact.
- `.github/workflows/bonaqu-upstream-check.yml` tracks Telegram Desktop upstream drift and validates the feature lifecycle registry.

## Upstream platform workflows

The inherited Telegram Desktop Linux, macOS, packaged macOS, Snap and generic Windows workflows are intentionally not carried as automatic workflows in the Bonaqu fork. They caused every Bonaqu Windows-focused feature PR to fan out into unrelated platform jobs.

This does **not** mean upstream platform support is assumed broken or ignored. During an upstream sync, platform-specific upstream changes are reviewed in the upstream repository and Bonaqu can temporarily restore or run the relevant upstream workflow in a dedicated sync branch when cross-platform verification becomes a project target.

When importing future upstream changes, `.github/workflows/` is treated as a Bonaqu-owned integration area: do not blindly restore removed upstream build workflows. Review upstream CI changes and port only the parts useful to Bonaqu's current supported targets.
