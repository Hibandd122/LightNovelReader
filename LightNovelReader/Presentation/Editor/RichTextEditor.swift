import SwiftUI
import UIKit

public struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    
    public init(attributedText: Binding<NSAttributedString>) {
        self._attributedText = attributedText
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
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
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
    }
}
