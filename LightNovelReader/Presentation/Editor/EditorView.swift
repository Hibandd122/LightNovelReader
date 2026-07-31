import SwiftUI

public struct EditorView: View {
    let novel: Novel
    @StateObject private var viewModel = EditorViewModel()
    
    public init(novel: Novel) {
        self.novel = novel
    }
    
    public var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Editor...")
            } else {
                RichTextEditor(
                    attributedText: $viewModel.attributedText,
                    selectedRange: $viewModel.selectedRange
                )
                .padding()
                .onChange(of: viewModel.attributedText.string) { _ in
                    viewModel.documentDidChange()
                }
            }
        }
        .navigationTitle("Editor")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text(viewModel.saveStatusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            viewModel.loadDocument(for: novel)
        }
    }
}