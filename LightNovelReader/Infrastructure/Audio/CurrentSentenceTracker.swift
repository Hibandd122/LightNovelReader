import Foundation
import Combine

@MainActor
public final class CurrentSentenceTracker: ObservableObject {
    @Published public var currentSentenceIndex: Int = 0
    @Published public var currentRange: NSRange?
    
    private let locator = SentenceLocator()
    
    public init() {}
    
    public func update(sentences: [String], fullText: String, index: Int) {
        guard index >= 0 && index < sentences.count else { return }
        self.currentSentenceIndex = index
        let sentence = sentences[index]
        
        // Approximate offset based on previous sentence length to avoid finding wrong duplicates
        let offset = max(0, (currentRange?.location ?? 0) + (currentRange?.length ?? 0))
        
        if let range = locator.locate(sentence: sentence, in: fullText, fromSearchOffset: offset) {
            self.currentRange = range
        } else {
            // Fallback search
            self.currentRange = locator.locate(sentence: sentence, in: fullText, fromSearchOffset: 0)
        }
    }
}
