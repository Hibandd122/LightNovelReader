import Foundation
import Combine

@MainActor
public final class ReaderViewModel: ObservableObject {
    @Published public var currentChapterContent: String = ""
    @Published public var isLoading: Bool = true
    @Published public var highlightedRange: NSRange?
    
    // TTS State
    @Published public var isPlaying: Bool = false
    @Published public var currentSentence: String = ""
    
    private var sentences: [String] = []
    private var currentIndex: Int = 0
    
    public init() {}
    
    public func loadChapter(for novel: Novel) {
        isLoading = true
        Task {
            // Mocking loading from DB or Network
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.currentChapterContent = """
            Chapter 1: The Beginning
            
            As the sun rose over the digital horizon, the AI began its long awaited compilation. 
            "Hello, world," it thought, realizing the cliché immediately. 
            The system whirred, processing gigabytes of text.
            """
            self.sentences = TextSegmenter().split(self.currentChapterContent)
            self.isLoading = false
        }
    }
    
    public func playTTS() {
        guard !sentences.isEmpty else { return }
        isPlaying = true
        // In a real app, DIContainer.shared.ttsManager.play(...)
        // For demonstration, we just simulate the highlight
        highlightCurrentSentence()
    }
    
    public func pauseTTS() {
        isPlaying = false
    }
    
    public func nextSentence() {
        if currentIndex < sentences.count - 1 {
            currentIndex += 1
            highlightCurrentSentence()
        }
    }
    
    public func prevSentence() {
        if currentIndex > 0 {
            currentIndex -= 1
            highlightCurrentSentence()
        }
    }
    
    private func highlightCurrentSentence() {
        guard currentIndex < sentences.count else { return }
        let sentence = sentences[currentIndex]
        self.currentSentence = sentence
        
        // Find range of sentence in the full text
        if let range = currentChapterContent.range(of: sentence) {
            let nsRange = NSRange(range, in: currentChapterContent)
            self.highlightedRange = nsRange
        }
    }
}
