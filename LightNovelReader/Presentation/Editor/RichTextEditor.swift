import SwiftUI
import UIKit

public struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    
    public init(attributedText: Binding<NSAttributedString>, selectedRange: Binding<NSRange> = .constant(NSRange(location: 0, length: 0))) {
        self._attributedText = attributedText
        self._selectedRange = selectedRange
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        
        // Attach UndoManager natively supported by UITextView
        textView.allowsEditingTextAttributes = true
        
        return textView
    }
    
    public func updateUIView(_ uiView: UITextView, context: Context) {
        if !uiView.attributedText.isEqual(to: attributedText) {
            uiView.attributedText = attributedText
        }
        if uiView.selectedRange != selectedRange {
            uiView.selectedRange = selectedRange
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        public func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}