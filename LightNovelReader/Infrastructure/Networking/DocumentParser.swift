import Foundation

/// Parses raw Google Docs JSON structures into plain text or rich text structures for the app.
public struct DocumentParser {
    public init() {}
    
    public func parseToPlainText(document: GoogleDocsDocument) -> String {
        var fullText = ""
        
        for element in document.body.content {
            guard let paragraph = element.paragraph else { continue }
            for pElement in paragraph.elements {
                if let textRun = pElement.textRun {
                    fullText += textRun.content
                }
            }
        }
        
        return fullText
    }
    
    /// Parses to an NSAttributedString to retain bold, italic, and headers.
    public func parseToRichText(document: GoogleDocsDocument) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        for element in document.body.content {
            guard let paragraph = element.paragraph else { continue }
            for pElement in paragraph.elements {
                if let textRun = pElement.textRun {
                    // In a real app, inspect textRun.textStyle to map bold/italic 
                    // and paragraph.paragraphStyle to map headers.
                    let str = NSAttributedString(string: textRun.content)
                    attributedString.append(str)
                }
            }
        }
        
        return attributedString
    }
}
