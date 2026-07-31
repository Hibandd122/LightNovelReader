import SwiftUI
import SwiftData

public struct BookmarkView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(bookmarks) { bookmark in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookmark.title).font(.headline)
                        Text(bookmark.tag ?? bookmark.folderName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    offsets.map { bookmarks[$0] }.forEach(modelContext.delete)
                    try? modelContext.save()
                }
            }
            .overlay {
                if bookmarks.isEmpty { ContentUnavailableView("Chưa có bookmark", systemImage: "bookmark") }
            }
            .navigationTitle("Bookmark")
        }
    }
}