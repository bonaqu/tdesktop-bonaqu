# Bonaqu Desktop WEB Proxy test guide

This guide is for the experimental Windows x64 build produced by `.github/workflows/bonaqu-win64.yml`.

## Important limitations

The current build uses Telegram Desktop's official **TEST ONLY** API credentials through `TDESKTOP_API_TEST=ON`. Telegram documents these credentials as heavily limited and unsuitable for deployment. Login may eventually return internal server errors. Replace test credentials with a dedicated `api_id` / `api_hash` before treating Bonaqu Desktop as a normal distributable client.

WEB Proxy itself is new upstream code. Passing a build is not enough to declare the transport stable: the upstream `docs/web-proxy-test-plan.md` requires live relay P0/P1 testing, including reconnects, large transfers, concurrency and failure injection.

## Safe first launch

1. Extract the complete GitHub Actions artifact to its own folder.
2. Do **not** copy your normal Telegram Desktop `tdata` directory into it.
3. Start `Start-Bonaqu-Desktop.cmd`, not the executable directly.
4. The launcher uses `-workdir <artifact>\BonaquProfile`, giving the experimental build an isolated profile.
5. Keep `BUILD-INFO.txt` and `SHA256SUMS.txt` with the build so the source commit and binary hash remain traceable.

For diagnostics, use `Start-Bonaqu-Desktop-Debug.cmd`. Review logs for private information before sharing them.

## WEB Proxy configuration

A compatible hosted relay is required. The client is only one half of WEB Proxy.

Open:

`Settings -> Advanced -> Connection type -> Proxy settings -> Add proxy -> WEB`

Enter:

- relay hostname only, without `https://`, port, path, query or fragment;
- the MTProxy secret accepted by WEB Proxy.

The WEB implementation fixes the relay port at 443. TLS-emulation (`ee`) MTProxy secrets are intentionally unsupported by this WEB relay design.

## Minimum smoke test

Record the exact Bonaqu build commit and relay version, then verify:

1. Saving an invalid hostname is rejected.
2. Saving an invalid or unsupported secret is rejected.
3. Enabling the WEB entry changes it from connecting to online.
4. No system browser opens during normal hidden-WebView operation.
5. Dialogs load and incoming updates arrive.
6. Send and receive a plain private message.
7. Send and receive a small image/file.
8. Disable WEB and confirm the client returns to the normal connection policy.
9. Re-enable the same WEB entry and confirm it reconnects.
10. Restart Bonaqu Desktop through the launcher and confirm the isolated profile and saved WEB entry remain intact.

## Extended test before calling it stable

Use the upstream `docs/web-proxy-test-plan.md` as the source of truth. Important coverage includes:

- fresh-account login and 2FA;
- message edits/deletes/reactions/read receipts;
- downloads and uploads large enough to exercise flow control repeatedly;
- a file larger than 1 GiB;
- concurrent downloads plus an upload;
- idle connection recovery;
- network down/up and sleep/wake;
- hidden WebView failure and explicit browser fallback;
- relay and stock-MTProxy restarts;
- malformed relay frames and flow-control violations in staging;
- long-running memory/queue observation;
- socket destruction races under sanitizers where practical.

Do not call the transport stable until the relevant upstream P0/P1 cases pass against the relay deployment you intend to use.

## What to collect when a bug occurs

Useful information:

- Bonaqu source commit from `BUILD-INFO.txt`;
- Windows version;
- whether normal or debug launcher was used;
- WEB Proxy state shown in settings;
- exact reproduction steps;
- whether direct Telegram / SOCKS / MTProxy works on the same network;
- sanitized debug log around the failure;
- relay version and sanitized server-side failure reason if available.

Do **not** publish:

- Telegram authorization keys;
- account session files;
- cookies/tokens;
- message contents;
- the WEB Proxy MTProxy secret;
- the generated bridge capability / browser fragment;
- unreviewed debug logs.
