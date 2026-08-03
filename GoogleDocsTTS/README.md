# GoogleDocsTTS

Rootless Theos dylib for local, presentation-only reading assistance in Google Docs. The implementation is intentionally scoped to documents already visible to the signed-in user; it does not add a network document client or bypass access controls.

## Architecture

- `GDTWebTextSource`, `GDTDefaultNormalizer`, and `GDTSentenceSegmenter` form the extraction pipeline and produce stable document/section/paragraph/sentence/word IDs. The structured source preserves headings, lists, tables, footnotes, hyperlinks, and image alt text when exposed by the editor DOM.
- `GDTTTSEngine`, `GDTVoiceProvider`, `GDTSpeechRequest`, and `GDTSpeechDelegate` keep speech providers replaceable; `GDTSpeechEngine` uses `AVSpeechSynthesizer`.
- `GDTSQLiteStore` provides normalized persistence for documents, bookmarks, history, sessions, voices, settings, cache metadata, and statistics. `GDTUserDefaultsStore` is a failure-safe fallback.
- `GDTDOMHighlightEngine` selects the current sentence in the existing DOM and optionally scrolls it into view without inserting editor markup.
- `GDTSystemPlaybackCoordinator` configures spoken-audio playback, Now Playing metadata, and lock-screen/Control Center commands.
- `GDTSerialReadingQueue` supplies a thread-safe FIFO for multi-document continuation.
- `GDTSettingsViewController` exposes the dynamic injected settings surface, including voice identifier, speed, pitch, volume, highlight mode, auto-scroll, position retention, and sleep timer.
- `GDTReadingController` keeps parsing and persistence off the main thread while UI and DOM operations return to it.

The tweak is filtered to `com.google.Docs`, fails closed when no document text is available, and does not send document content to a network service.

Build on macOS with Theos:

```sh
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

## Delivery roadmap

1. Core model and parser pipeline: implemented.
2. TTS abstraction, resume persistence, SQLite schema, selection/highlight, and system playback: implemented at service level.
3. Injected mini-player/settings surface, reading queue, sleep timer, statistics UI, and richer table/footnote extraction: next integration phase.
4. Build on a macOS Theos runner, install on a test device, and validate against multiple Google Docs editor variants.

## Verification note

The shared workspace is Windows and does not contain Apple SDKs or Theos, so ARM64 compilation and device behavior must be verified by the included macOS GitHub Actions workflow or a local macOS Theos environment.
