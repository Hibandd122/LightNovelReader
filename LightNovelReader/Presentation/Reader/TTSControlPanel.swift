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
                
                Button(action: {
                    viewModel.nextSentence()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 10)
        )
        .padding()
    }
}
