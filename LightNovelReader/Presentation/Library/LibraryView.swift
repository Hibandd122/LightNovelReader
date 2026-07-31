import SwiftUI
import SwiftData

public struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Novel.lastModified, order: .reverse) private var novels: [Novel]
    
    @StateObject private var viewModel = LibraryViewModel()
    @ObservedObject private var syncManager = DIContainer.shared.syncManager
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Group {
                if novels.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Chưa có volume")
                            .font(.headline)
                        Button("Tải Vol 9") {
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
            .navigationTitle("Light Novel")
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
        .onAppear {
            DIContainer.shared.syncManager.configure(context: modelContext)
        }
        .alert("Tài liệu đã thay đổi trên Google Docs", isPresented: Binding(
            get: { syncManager.conflictDocumentID != nil },
            set: { if !$0 { syncManager.clearConflict() } }
        )) {
            Button("Tải lại bản Google Docs", role: .destructive) {
                Task {
                    await viewModel.syncFromGoogleDocs(context: modelContext)
                    syncManager.clearConflict()
                }
            }
            Button("Để sau", role: .cancel) { syncManager.clearConflict() }
        } message: {
            Text("Bản online đã thay đổi. Hãy tải lại trước khi tiếp tục sửa để tránh ghi đè nội dung mới.")
        }
        .alert("Không thể đồng bộ", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "Đã xảy ra lỗi không xác định.")
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
                Text("Cập nhật: \(novel.lastModified, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
