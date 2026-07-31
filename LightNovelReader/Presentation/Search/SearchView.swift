import SwiftUI
import SwiftData

public struct SearchView: View {
    private struct SearchResult: Identifiable {
        let novel: Novel
        let chapter: Chapter?
        var id: String { novel.id }
    }

    @Query private var novels: [Novel]
    @State private var searchText = ""

    public init() {}

    private var results: [SearchResult] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return novels.map { SearchResult(novel: $0, chapter: $0.chapters.first) } }
        return novels.flatMap { novel in
            let titleMatch = novel.title.localizedCaseInsensitiveContains(query)
            let chapterMatch = novel.chapters.first { $0.title.localizedCaseInsensitiveContains(query) || $0.content.localizedCaseInsensitiveContains(query) }
            guard titleMatch || chapterMatch != nil else { return [] }
            return [SearchResult(novel: novel, chapter: chapterMatch)]
        }
    }

    public var body: some View {
        NavigationStack {
            List(results) { result in
                NavigationLink {
                    ReaderView(novel: result.novel)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.novel.title).font(.headline)
                        if let chapter = result.chapter {
                            Text(chapter.title).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if results.isEmpty { ContentUnavailableView("Không tìm thấy", systemImage: "magnifyingglass") }
            }
            .navigationTitle("Tìm kiếm")
            .searchable(text: $searchText, prompt: "Tìm truyện, chương hoặc nội dung")
        }
    }
}