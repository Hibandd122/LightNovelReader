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
                TextEditor(text: $viewModel.text)
                    .padding()
                    .font(.body)
                    .onChange(of: viewModel.text) { _ in
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
