import Foundation

public struct TextSegmenter {
    private let sentenceTerminators: Set<Unicode.Scalar> = [".", "!", "?", "。", "！", "？", "…"]
    private let hardTerminators: Set<Unicode.Scalar> = ["。", "！", "？"]
    private let closingQuotes: Set<Unicode.Scalar> = ["\"", "'", "”", "’", "」", "』", "》", "〉", "】", ")", "]", "}"]

    public init() {}

    public func split(_ text: String) -> [String] {
        let scalars = Array(text.unicodeScalars)
        guard !scalars.isEmpty else { return [] }

        var result: [String] = []
        var start = 0
        var index = 0

        while index < scalars.count {
            let scalar = scalars[index]
            let isParagraphBreak = scalar == "\n" && index + 1 < scalars.count && scalars[index + 1] == "\n"
            let isTerminator = sentenceTerminators.contains(scalar)
            guard isTerminator || isParagraphBreak else {
                index += 1
                continue
            }

            var end = isParagraphBreak ? index : index + 1
            while end < scalars.count && closingQuotes.contains(scalars[end]) { end += 1 }
            if isTerminator {
                while end < scalars.count && sentenceTerminators.contains(scalars[end]) { end += 1 }
            }

            let next = end < scalars.count ? scalars[end] : nil
            let canBreak = next == nil || next?.properties.isWhitespace == true || isParagraphBreak || hardTerminators.contains(scalar)
            if canBreak {
                append(String(scalars[start..<end].map { String($0) }.joined()), to: &result)
                start = end
            }
            index = max(end, index + 1)
        }

        if start < scalars.count {
            append(String(scalars[start...].map { String($0) }.joined()), to: &result)
        }
        return result
    }

    private func append(_ value: String, to result: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { result.append(trimmed) }
    }
}