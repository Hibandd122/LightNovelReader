import SwiftUI
import CoreSpotlight
import SwiftData

public struct ReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let novel: Novel
    @StateObject private var viewModel = ReaderViewModel()
    
    @State private var showControls = false
    @State private var showTTS = false
    @AppStorage("appTheme") private var appTheme = AppThemeType.system.rawValue
    @State private var bookmarkMessage: String?
    
    public init(novel: Novel) {
        self.novel = novel
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: themeConfig.backgroundColor).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                ProgressView("Loading Chapter...")
            } else {
                TextKit2View(
                    text: viewModel.currentChapterContent,
                    highlightedRange: viewModel.highlightedRange,
                    textColor: themeConfig.textColor
                )
                    .onTapGesture {
                        withAnimation {
                            showControls.toggle()
                        }
                    }
                    .edgesIgnoringSafeArea(showControls ? [] : .all)
            }
            
            if showTTS {
                VStack {
                    Spacer()
                    TTSControlPanel(viewModel: viewModel)
                        .transition(.move(edge: .bottom))
                }
                .zIndex(1)
            }
        }
        .navigationBarHidden(!showControls)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showTTS.toggle()
                    }
                }) {
                    Image(systemName: "headphones")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditorView(novel: novel)) {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Mở trình chỉnh sửa")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addBookmark) {
                    Image(systemName: "bookmark")
                }
                .accessibilityLabel("Lưu dấu trang tại câu hiện tại")
            }
        }
        .onAppear {
            viewModel.loadChapter(for: novel)
        }
        .onDisappear {
            viewModel.stopTTS()
        }
        .alert("Dấu trang", isPresented: Binding(
            get: { bookmarkMessage != nil },
            set: { if !$0 { bookmarkMessage = nil } }
        )) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(bookmarkMessage ?? "")
        }
        // MARK: - Handoff & Continuity Support
        .userActivity("com.lightnovelreader.reading", element: novel) { novel, activity in
            activity.title = "Reading \(novel.title)"
            // activity.userInfo = ["novelId": novel.id]
            activity.isEligibleForHandoff = true
            activity.isEligibleForSearch = true
            
            // Spotlight Search indexing
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = novel.title
            attributes.authorNames = [novel.author ?? "Unknown"]
            activity.contentAttributeSet = attributes
        }
    }

    private var themeConfig: ThemeConfig {
        let engine = ThemeEngine()
        engine.currentThemeType = AppThemeType(rawValue: appTheme) ?? .system
        return engine.currentConfig
    }

    private func addBookmark() {
        guard let chapter = novel.chapters.first,
              let range = viewModel.highlightedRange else {
            bookmarkMessage = "Hãy chọn hoặc bắt đầu đọc một câu trước khi lưu dấu trang."
            return
        }
        let bookmark = Bookmark(
            novelId: novel.id,
            chapterId: chapter.id,
            locationIndex: range.location,
            title: viewModel.currentSentence.isEmpty ? chapter.title : viewModel.currentSentence
        )
        modelContext.insert(bookmark)
        do {
            try modelContext.save()
            bookmarkMessage = "Đã lưu dấu trang."
        } catch {
            modelContext.delete(bookmark)
            bookmarkMessage = "Không thể lưu dấu trang: \(error.localizedDescription)"
        }
    }
}
