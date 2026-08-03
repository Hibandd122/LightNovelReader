# Architecture and implementation notes

## Core and models

`GDTModels` owns serializable value objects only. The parser produces a stable hierarchy: one document contains sections, sections contain paragraphs, paragraphs contain sentences, and sentences contain words. Ranges are offsets into normalized text and are therefore suitable for resume and cache validation.

Threading: models are immutable by convention after parsing. A session is mutated by the reading controller on the main queue; stores serialize writes onto their own queue.

## Parser

`GDTTextSource` is the only component that knows how to query a `WKWebView`. Normalization, segmentation, and hierarchy assembly are separate dependencies. Parsing and hashing run on a user-initiated background queue. Completion returns on the main queue. `parseText:` is used for selected-text and future accessibility entry points.

The DOM source now emits typed blocks for headings, lists, tables, footnotes, links, images with alt text, and paragraphs. It falls back to visible text when the editor variant exposes no block nodes. Comments remain an optional future selector because their DOM representation varies between Docs editor versions.

## Reading and TTS

The controller owns state transitions and never depends on `AVSpeechSynthesizer` directly. `GDTTTSEngine` consumes speech requests; `GDTVoiceProvider` enumerates voices; delegates observe lifecycle events. A cloud/offline provider can be added without changing parser, stores, or UI.

## Persistence

`GDTSQLiteStore` uses a serial queue and WAL mode. Documents are cacheable by `(document_id, content_hash)`. Reading sessions, bookmarks, history, settings, and statistics have separate tables. `GDTUserDefaultsStore` is a recoverable fallback for initialization failures.

## UI, highlight, and playback

The injected button is installed per visible view controller, with a stable tag preventing duplicates. Its long-press menu supports full document, selection, cursor, and settings entry points. `GDTSettingsViewController` edits persisted voice/rate/pitch/volume/highlight/scroll/remember/sleep settings. DOM highlighting uses the browser selection API and does not rewrite editor HTML. `GDTSystemPlaybackCoordinator` owns audio session, Now Playing metadata, and remote command handlers.

## Known next integration work

- Build a settings/mini-player surface backed by `GDTSettings`.
- Add structured DOM extraction for headings, lists, tables, footnotes, links, images, and comments.
- Add selected-text and cursor actions to the injected menu.
- Add word-level timing callbacks for true word highlighting.
- Add UI for queue, bookmarks, history, statistics, and continue-reading prompt.
- Run device tests across editor, viewer, offline, dark-mode, rotation, and large-document cases on macOS/Theos.
