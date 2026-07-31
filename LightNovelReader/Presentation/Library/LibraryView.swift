import SwiftUI
import SwiftData

public struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Novel.lastModified, order: .reverse) private var novels: [Novel]
    
    @StateObject private var viewModel = LibraryViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Group {
                if novels.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Novels Found")
                            .font(.headline)
                        Button("Sync from Google Docs") {
                            Task {
                                await viewModel.syncFromGoogleDocs(context: modelContext)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(novels) { novel in
                            NavigationLink(destination: ReaderView(novel: novel)) {
                                NovelRow(novel: novel)
                            }
                        }
                        .onDelete(perform: deleteNovels)
                    }
                    .refreshable {
                        await viewModel.syncFromGoogleDocs(context: modelContext)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSyncing {
                        ProgressView()
                    } else {
                        Button(action: {
                            Task { await viewModel.syncFromGoogleDocs(context: modelContext) }
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
        }
    }
    
    private func deleteNovels(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(novels[index])
            }
        }
    }
}

struct NovelRow: View {
    let novel: Novel
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder for Cover
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 80)
                .cornerRadius(4)
                .overlay(
                    Image(systemName: "book")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(novel.title)
                    .font(.headline)
                    .lineLimit(2)
                if let author = novel.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("Last modified: \(novel.lastModified, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
