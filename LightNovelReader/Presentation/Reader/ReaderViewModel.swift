import Foundation
import Combine

@MainActor
public final class ReaderViewModel: ObservableObject {
    @Published public var currentChapterContent = ""
    @Published public var isLoading = true
    @Published public var highlightedRange: NSRange?
    @Published public var isPlaying = false
    @Published public var currentSentence = ""
    @Published public var ttsError: String?

    private let ttsManager: TTSManager
    private let sentenceLocator = SentenceLocator()
    private var sentences: [String] = []
    private var sentenceRanges: [NSRange?] = []
    private var currentIndex = 0
    private weak var currentChapter: Chapter?

    public init(ttsManager: TTSManager = DIContainer.shared.ttsManager) {
        self.ttsManager = ttsManager
        ttsManager.onSentenceChanged = { [weak self] index in
            self?.updateCurrentSentence(index)
        }
        ttsManager.onPlaybackFinished = { [weak self] in
            self?.isPlaying = false
        }
        ttsManager.onPlaybackError = { [weak self] message in
            self?.isPlaying = false
            self?.ttsError = message
        }
        ttsManager.onNextSentence = { [weak self] in self?.nextSentence() }
        ttsManager.onPreviousSentence = { [weak self] in self?.prevSentence() }
    }

    public func loadChapter(for novel: Novel) {
        stopTTS()
        isLoading = true
        currentChapter = novel.chapters.first
        ttsManager.configureNowPlaying(
            title: novel.title,
            author: novel.author,
            chapter: currentChapter?.title ?? ""
        )
        currentChapterContent = novel.chapters.first?.content ?? "Chưa có nội dung chương. Hãy đồng bộ tài liệu trước."
        sentences = TextSegmenter().split(currentChapterContent)
        sentenceRanges = locateRanges(sentences, in: currentChapterContent)
        currentIndex = 0
        highlightedRange = nil
        currentSentence = sentences.first ?? ""
        isLoading = false
    }

    public func playTTS() {
        guard !sentences.isEmpty else { return }
        ttsError = nil
        if case .paused = ttsManager.state {
            ttsManager.resume()
        } else {
            ttsManager.start(sentences: sentences, startingIndex: currentIndex)
        }
        isPlaying = true
        updateCurrentSentence(currentIndex)
    }

    public func pauseTTS() {
        ttsManager.pause()
        isPlaying = false
    }

    public func setSpeakingRate(_ rate: Float) {
        ttsManager.speakingRate = rate
    }

    public func stopTTS() {
        ttsManager.stop()
        persistProgress()
        isPlaying = false
    }

    public func nextSentence() {
        guard currentIndex < sentences.count - 1 else { return }
        currentIndex += 1
        updateCurrentSentence(currentIndex)
        if isPlaying { ttsManager.start(sentences: sentences, startingIndex: currentIndex) }
    }

    public func prevSentence() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        updateCurrentSentence(currentIndex)
        if isPlaying { ttsManager.start(sentences: sentences, startingIndex: currentIndex) }
    }

    private func updateCurrentSentence(_ index: Int) {
        guard sentences.indices.contains(index) else { return }
        currentIndex = index
        currentSentence = sentences[index]
        highlightedRange = sentenceRanges[index]
        persistProgress()
    }

    private func locateRanges(_ sentences: [String], in text: String) -> [NSRange?] {
        var offset = 0
        return sentences.map { sentence in
            let range = sentenceLocator.locate(sentence: sentence, in: text, fromSearchOffset: offset)
            if let range { offset = range.location + range.length }
            return range
        }
    }

    private func persistProgress() {
        guard let chapter = currentChapter, !sentences.isEmpty else { return }
        chapter.readingProgress = min(1, Float(currentIndex + 1) / Float(sentences.count))
        chapter.lastReadAt = Date()
        try? chapter.modelContext?.save()
    }
}