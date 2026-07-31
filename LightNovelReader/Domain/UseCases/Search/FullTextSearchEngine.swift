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
        // Re-indexing must replace old postings, otherwise every edit inflates
        // scores and leaves matches for text that no longer exists.
        for token in Array(invertedIndex.keys) {
            invertedIndex[token]?.removeAll { $0.0 == chapterId }
            if invertedIndex[token]?.isEmpty == true {
                invertedIndex[token] = nil
            }
        }
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
        
        var groupedResults: [String: SearchResult] = [:]
        
        // Simple OR search for demonstration (Ranking by frequency)
        for token in queryTokens {
            if let chapterMatches = invertedIndex[token] {
                for (chapterId, indices) in chapterMatches {
                    let score = indices.count
                    guard let content = documentStore[chapterId] else { continue }
                    
                    let snippet = generateSnippet(content: content, query: query)
                    let matchRange = content.localizedStandardRange(of: query).map { NSRange($0, in: content) }
                        ?? content.localizedStandardRange(of: token).map { NSRange($0, in: content) }
                        ?? NSRange(location: 0, length: 0)
                    let result = SearchResult(chapterId: chapterId, snippet: snippet, matchRange: matchRange, score: score)
                    if let previous = groupedResults[chapterId], previous.score >= score {
                        continue
                    }
                    groupedResults[chapterId] = result
                }
            }
        }
        
        // Group by chapterId and sort by score
        return groupedResults.values.sorted { $0.score > $1.score }
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