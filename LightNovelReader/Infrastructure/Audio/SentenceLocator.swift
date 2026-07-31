import Foundation

public struct SentenceLocator {
    public init() {}
    
    /// Finds the exact NSRange of a given sentence within the full text.
    /// Handles multiple identical sentences by using an occurrence index or offset context.
    public func locate(sentence: String, in fullText: String, fromSearchOffset offset: Int = 0) -> NSRange? {
        let utf16Offset = min(max(offset, 0), fullText.utf16.count)
        let searchStart = String.Index(utf16Offset: utf16Offset, in: fullText)
        guard let range = fullText.range(of: sentence, options: [], range: searchStart..<fullText.endIndex) else {
            // Fallback to searching from beginning if not found after offset
            guard let fallbackRange = fullText.range(of: sentence) else { return nil }
            return NSRange(fallbackRange, in: fullText)
        }
        return NSRange(range, in: fullText)
    }
}