# Test strategy

`GDTParserTests.mm` uses a mock text source so parser business logic can be tested without Google Docs, a network connection, or a real editor DOM. The tests cover normalization, sentence/word indexing, hierarchy assembly, fail-closed empty input, and stable document IDs.

On macOS, add `Tests` to an XCTest bundle target and link the `Sources` files. The Theos package itself does not ship XCTest; device smoke tests should separately cover injection, lifecycle, audio interruption, background playback, rotation, dark mode, VoiceOver, and large documents.
