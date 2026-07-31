import SwiftUI
import UIKit

/// A UIViewRepresentable wrapping UITextView to utilize TextKit 2 for high performance text rendering.
public struct TextKit2View: UIViewRepresentable {
    public var text: String
    public var highlightedRange: NSRange?
    public var textColor: UIColor

    public init(text: String, highlightedRange: NSRange? = nil, textColor: UIColor = .label) {
        self.text = text
        self.highlightedRange = highlightedRange
        self.textColor = textColor
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(usingTextLayoutManager: true)
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        
        return textView
    }
    
    public func updateUIView(_ uiView: UITextView, context: Context) {
        // Set text if changed
        if uiView.text != text {
            uiView.text = text
        }
        
        // Apply highlight
        let attributedString = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: textColor
        ])
        
        if let range = highlightedRange {
            attributedString.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.3), range: range)
            
            // Auto scroll to highlight
            uiView.scrollRangeToVisible(range)
        }
        
        uiView.attributedText = attributedString
    }
}