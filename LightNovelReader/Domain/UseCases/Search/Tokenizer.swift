import Foundation

public struct Tokenizer {
    public init() {}
    
    /// Normalizes and splits a body of text into searchable tokens.
    public func tokenize(_ text: String) -> [String] {
        let lowercased = text.lowercased()
        
        // Remove punctuation and diacritics (optional based on language config)
        let folded = lowercased.folding(options: .diacriticInsensitive, locale: .current)
        
        let words = folded.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        return words.filter { $0.count > 2 } // Ignore stop words / very short words
    }
}
