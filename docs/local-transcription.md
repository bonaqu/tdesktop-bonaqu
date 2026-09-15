# Bonaqu local voice transcription

Bonaqu Client will treat local speech-to-text as an optional privacy-oriented feature. It is not a replacement for Telegram account entitlements and must never spoof Telegram Premium or server-side transcription state.

## Engine choice

Initial engine: [`ggml-org/whisper.cpp`](https://github.com/ggml-org/whisper.cpp)

Pinned source commit:

```text
233fe1fc9b48a09e361d3594520838ca266537fe
```

The pin is deliberate. CI and packaged optional engines must build from an exact reviewed commit, never a floating `master` reference.

At the pinned revision, whisper.cpp declares MIT licensing, supports CMake builds, exposes a standalone examples/CLI build, and has a Windows CI configuration. Bonaqu should keep its attribution/license file next to any redistributed engine binaries.

## Architecture

### Base client

The normal Bonaqu installer stays independent from model weights. The client contains only:

- local-transcription UI and state;
- model/engine discovery;
- download/install/remove controls;
- task progress and cancellation;
- safe handoff of decoded local audio to the transcription worker;
- transcript rendering/copy/search integration.

No Whisper model is downloaded until the user explicitly requests local transcription or installs a model in Settings.

### Worker boundary

The first implementation should run transcription out-of-process rather than loading the model directly into the Telegram Desktop process.

Reasons:

- a crash or out-of-memory error in the ML runtime should not terminate the chat client;
- engine/model updates can be versioned independently from the main client;
- the worker can have a narrowly defined local IPC/input-output contract;
- GPU backend failures can fall back to CPU without destabilising Telegram UI state.

The worker must not make network requests during transcription.

Suggested task contract:

```text
input:
  task id
  local decoded PCM/WAV path
  model id/path
  language: auto | explicit language
  optional backend preference

output:
  task id
  state: running | completed | cancelled | failed
  detected language
  segments with start/end timestamps
  plain transcript
  diagnostic error code (no message/account data)
```

Temporary audio and worker result files should live inside the active Bonaqu workdir and be removed after completion/cancellation unless the user explicitly exports them.

## Audio pipeline

Do not shell out to a random system `ffmpeg.exe` from the UI.

Telegram Desktop already has its own media decoding stack. The integration should use existing Telegram media/audio decoding primitives to produce the worker input format. The worker-facing canonical format should be mono PCM at the sample rate required by the selected engine (Whisper commonly uses 16 kHz audio).

Audio conversion belongs in a narrow Bonaqu adapter so upstream media changes can be rebased without forking Telegram's playback code.

## Models

Models are optional data, not application files.

Recommended initial choices:

- **Base multilingual** — default lightweight option for general voice messages.
- **Small multilingual** — optional higher-quality/larger choice.

The Settings UI must show the exact download size before installation, model source, installed size, checksum verification state, and a Remove button.

Each supported model entry should be pinned by:

- canonical filename;
- immutable or versioned source URL;
- expected SHA-256;
- expected byte size;
- engine compatibility version.

A download is not marked installed until its hash matches.

## Backend strategy

Phase 1: CPU is the required baseline because it is the easiest path to support consistently and debug.

Phase 2 can add an optional GPU backend only after repeatable Windows packaging is proven. whisper.cpp/ggml has several acceleration paths; Bonaqu should choose one Windows path deliberately rather than ship every backend and dependency.

Backend failure must produce a clear local error and allow a retry on CPU.

## UI/UX

Planned message action:

**Transcribe locally**

Possible states:

- model not installed → explain size/privacy and offer install;
- queued/downloading model;
- transcribing locally with cancel action;
- completed transcript with copy/search controls;
- failed with a safe reason and retry option.

The result should visibly say that it was processed locally. Do not use Telegram Premium badges or wording that implies Telegram servers produced the transcript.

## Privacy rules

Local transcription diagnostics must not contain:

- account identifiers;
- chat/user names;
- message text;
- transcript text unless the user explicitly exports it;
- original absolute media path;
- Telegram API credentials;
- proxy credentials.

The feature never uploads the voice message to a Bonaqu service.

## Updates

The engine, models and client integration have separate versions.

- Engine updates require a reviewed pinned commit and reproducible Windows build.
- Model metadata updates require checksum review.
- Existing installed models continue working when compatible.
- If an engine update is incompatible, keep the previous worker until the new one is installed successfully.

## If Telegram ships equivalent local transcription

Follow `docs/upstream-sync-policy.md`:

1. Prefer Telegram's implementation for message/session integration.
2. If Telegram's local engine fully matches Bonaqu's privacy/offline goals, migrate Bonaqu settings and remove duplicate message hooks.
3. Keep only additive Bonaqu value such as alternative offline models/backends when this remains maintainable.
4. Never keep a second transcription pipeline merely to preserve a Bonaqu label.

## Implementation phases

1. **Engine build foundation** — reproducible pinned Windows worker/CLI artifact, no model bundled.
2. **Model manager** — manifest + verified download/remove flow.
3. **Audio adapter** — existing Telegram media data to canonical local worker input.
4. **Task service** — process management, cancellation, result parsing, cleanup.
5. **Message UI** — local transcription action and transcript view.
6. **Optional acceleration** — only after CPU path is stable.
