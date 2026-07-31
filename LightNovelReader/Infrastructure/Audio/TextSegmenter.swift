import Foundation

public struct TextSegmenter {
    public init() {}
    
    /// Splits a large text into sentences for TTS processing
    /// Respects Japanese and English quote marks and standard punctuation.
    public func split(_ text: String) -> [String] {
        // A robust implementation would use NaturalLanguage framework (NLTokenizer)
        // or complex Regex. For brevity, a simple split is demonstrated here.
        var result = [String]()
        
        let pattern = "(?<=[。！？.!?])\\s+(?=[^「”\"])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(text.startIndex..., in: text)
        var lastEndIndex = text.startIndex
        
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            let matchRange = Range(match.range, in: text)!
            let sentence = String(text[lastEndIndex..<matchRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                result.append(sentence)
            }
            lastEndIndex = matchRange.upperBound
        }
        
        let lastSentence = String(text[lastEndIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastSentence.isEmpty {
            result.append(lastSentence)
        }
        
        // Fallback if no punctuation is found
        return result.isEmpty ? [text] : result
    }
}
