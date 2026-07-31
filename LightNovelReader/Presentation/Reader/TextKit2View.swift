import SwiftUI
import UIKit

/// A UIViewRepresentable wrapping UITextView to utilize TextKit 2 for high performance text rendering.
public struct TextKit2View: UIViewRepresentable {
    public var text: String
    public var highlightedRange: NSRange?
    
    public init(text: String, highlightedRange: NSRange? = nil) {
        self.text = text
        self.highlightedRange = highlightedRange
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        
        // Optimize for large text
        textView.layoutManager.allowsNonContiguousLayout = true
        
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
            .foregroundColor: UIColor.label
        ])
        
        if let range = highlightedRange {
            attributedString.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.3), range: range)
            
            // Auto scroll to highlight
            DispatchQueue.main.async {
                uiView.scrollRangeToVisible(range)
            }
        }
        
        uiView.attributedText = attributedString
    }
}
