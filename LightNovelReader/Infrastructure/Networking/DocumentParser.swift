import Foundation
import UIKit

public struct DocumentParser {
    public struct ChapterDraft {
        public let id: String
        public let title: String
        public let content: String

        public init(id: String, title: String, content: String) {
            self.id = id
            self.title = title
            self.content = content
        }
    }

    public init() {}

    public func parseToPlainText(document: GoogleDocsDocument) -> String {
        bodies(for: document).map(plainText(from:)).joined()
    }

    public func parseToRichText(document: GoogleDocsDocument) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for body in bodies(for: document) {
            for element in body.content {
                guard let paragraph = element.paragraph else { continue }
                for part in paragraph.elements {
                    guard let run = part.textRun else { continue }
                    var attributes: [NSAttributedString.Key: Any] = [:]
                    if run.textStyle?.bold == true { attributes[.font] = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize) }
                    result.append(NSAttributedString(string: run.content, attributes: attributes))
                }
            }
        }
        return result
    }

    public func parseChapters(document: GoogleDocsDocument) -> [ChapterDraft] {
        if let tabs = document.tabs, !tabs.isEmpty {
            return tabs.sorted { ($0.tabProperties.index ?? 0) < ($1.tabProperties.index ?? 0) }.compactMap { tab in
                guard let body = tab.documentTab?.body else { return nil }
                return ChapterDraft(id: tab.tabProperties.tabId, title: tab.tabProperties.title, content: plainText(from: body))
            }
        }

        guard let body = document.body else { return [] }
        var drafts: [ChapterDraft] = []
        var title = document.title
        var content = ""
        var number = 0
        for element in body.content {
            guard let paragraph = element.paragraph else { continue }
            let text = paragraph.elements.compactMap { $0.textRun?.content }.joined()
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let isHeading = paragraph.paragraphStyle?.namedStyleType?.hasPrefix("HEADING") == true || trimmed.hasPrefix("Chương ") || trimmed.hasPrefix("Ngoại truyện:") || trimmed.hasPrefix("Lời bạt:")
            if isHeading && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drafts.append(ChapterDraft(id: "\(document.documentId)-\(number)", title: title, content: content))
                number += 1
                content = ""
            }
            if isHeading { title = trimmed } else { content += text }
        }
        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drafts.append(ChapterDraft(id: "\(document.documentId)-\(number)", title: title, content: content))
        }
        return drafts
    }

    private func bodies(for document: GoogleDocsDocument) -> [GoogleDocsBody] {
        let tabBodies = document.tabs?.compactMap { $0.documentTab?.body } ?? []
        return tabBodies.isEmpty ? (document.body.map { [$0] } ?? []) : tabBodies
    }

    private func plainText(from body: GoogleDocsBody) -> String {
        body.content.compactMap { element in
            element.paragraph?.elements.compactMap { $0.textRun?.content }.joined()
        }.joined()
    }
}
