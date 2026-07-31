import SwiftUI
import CoreSpotlight

public struct ReaderView: View {
    let novel: Novel
    @StateObject private var viewModel = ReaderViewModel()
    
    @State private var showControls = false
    @State private var showTTS = false
    @AppStorage("appTheme") private var appTheme = AppThemeType.system.rawValue
    
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
        }
        .onAppear {
            viewModel.loadChapter(for: novel)
        }
        .onDisappear {
            viewModel.stopTTS()
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
}
