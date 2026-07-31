import Foundation

public struct SearchResult {
    public let chapterId: String
    public let snippet: String
    public let matchRange: NSRange
    public let score: Int // For ranking
}

public actor FullTextSearchEngine {
    private let tokenizer = Tokenizer()
    
    // Inverted Index: Token -> [(ChapterID, Indices)]
    private var invertedIndex: [String: [(String, [Int])]] = [:]
    
    // Store original texts for snippets
    private var documentStore: [String: String] = [:]
    
    public init() {}
    
    public func index(chapterId: String, content: String) {
        documentStore[chapterId] = content
        let tokens = tokenizer.tokenize(content)
        
        for (index, token) in tokens.enumerated() {
            if invertedIndex[token] == nil {
                invertedIndex[token] = []
            }
            
            // Append or update existing chapter entry
            if let existingChapterIndex = invertedIndex[token]?.firstIndex(where: { $0.0 == chapterId }) {
                invertedIndex[token]?[existingChapterIndex].1.append(index)
            } else {
                invertedIndex[token]?.append((chapterId, [index]))
            }
        }
    }
    
    public func search(query: String) -> [SearchResult] {
        let queryTokens = tokenizer.tokenize(query)
        guard !queryTokens.isEmpty else { return [] }
        
        var results = [SearchResult]()
        
        // Simple OR search for demonstration (Ranking by frequency)
        for token in queryTokens {
            if let chapterMatches = invertedIndex[token] {
                for (chapterId, indices) in chapterMatches {
                    let score = indices.count
                    guard let content = documentStore[chapterId] else { continue }
                    
                    // Generate a snippet based on the first match
                    let snippet = generateSnippet(content: content, query: query)
                    // Compute NSRange for highlight UI
                    let nsRange = NSRange(location: 0, length: 0) // Computed in real implementation
                    
                    results.append(SearchResult(chapterId: chapterId, snippet: snippet, matchRange: nsRange, score: score))
                }
            }
        }
        
        // Group by chapterId and sort by score
        return results.sorted { $0.score > $1.score }
    }
    
    private func generateSnippet(content: String, query: String) -> String {
        // A robust snippet generator would find the exact query range and take +/- 50 chars.
        if let range = content.localizedStandardRange(of: query) {
            let start = content.index(range.lowerBound, offsetBy: -30, limitedBy: content.startIndex) ?? content.startIndex
            let end = content.index(range.upperBound, offsetBy: 30, limitedBy: content.endIndex) ?? content.endIndex
            return "..." + String(content[start..<end]).replacingOccurrences(of: "\n", with: " ") + "..."
        }
        return ""
    }
}
