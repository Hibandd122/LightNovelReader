import Foundation

public struct SentenceLocator {
    public init() {}
    
    /// Finds the exact NSRange of a given sentence within the full text.
    /// Handles multiple identical sentences by using an occurrence index or offset context.
    public func locate(sentence: String, in fullText: String, fromSearchOffset offset: Int = 0) -> NSRange? {
        guard let range = fullText.range(of: sentence, options: [], range: fullText.index(fullText.startIndex, offsetBy: offset)..<fullText.endIndex) else {
            // Fallback to searching from beginning if not found after offset
            guard let fallbackRange = fullText.range(of: sentence) else { return nil }
            return NSRange(fallbackRange, in: fullText)
        }
        return NSRange(range, in: fullText)
    }
}
