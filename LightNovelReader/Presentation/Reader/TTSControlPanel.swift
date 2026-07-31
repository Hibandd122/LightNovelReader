import SwiftUI

public struct TTSControlPanel: View {
    @ObservedObject var viewModel: ReaderViewModel
    
    public var body: some View {
        VStack(spacing: 16) {
            // Now Playing info
            Text(viewModel.currentSentence.isEmpty ? "Ready to play" : viewModel.currentSentence)
                .font(.subheadline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 32) {
                Button(action: {
                    viewModel.prevSentence()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Câu trước")
                
                Button(action: {
                    if viewModel.isPlaying {
                        viewModel.pauseTTS()
                    } else {
                        viewModel.playTTS()
                    }
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                }
                .accessibilityLabel(viewModel.isPlaying ? "Tạm dừng đọc" : "Đọc tiếp")
                
                Button(action: {
                    viewModel.nextSentence()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Câu tiếp theo")
            }

            Menu {
                Button("Chậm") { viewModel.setSpeakingRate(0.35) }
                Button("Bình thường") { viewModel.setSpeakingRate(0.5) }
                Button("Nhanh") { viewModel.setSpeakingRate(0.65) }
            } label: {
                Label("Tốc độ và giọng: Tiếng Việt", systemImage: "slider.horizontal.3")
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 10)
        )
        .padding()
        .alert("Không thể đọc to", isPresented: Binding(
            get: { viewModel.ttsError != nil },
            set: { if !$0 { viewModel.ttsError = nil } }
        )) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(viewModel.ttsError ?? "Đã xảy ra lỗi đọc to.")
        }
    }
}
