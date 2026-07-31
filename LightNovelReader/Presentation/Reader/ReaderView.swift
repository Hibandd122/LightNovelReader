import SwiftUI
import CoreSpotlight

public struct ReaderView: View {
    let novel: Novel
    @StateObject private var viewModel = ReaderViewModel()
    
    @State private var showControls = false
    @State private var showTTS = false
    
    public init(novel: Novel) {
        self.novel = novel
    }
    
    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                ProgressView("Loading Chapter...")
            } else {
                TextKit2View(text: viewModel.currentChapterContent, highlightedRange: viewModel.highlightedRange)
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
        }
        .onAppear {
            viewModel.loadChapter(for: novel)
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
}
