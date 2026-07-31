import Foundation
import Combine
import AVFoundation
import MediaPlayer

@MainActor
public final class TTSManager: ObservableObject {
    @Published public var state: TTSState = .idle
    
    private var provider: TTSProvider
    private let audioCache: AudioCacheManager
    
    public init(provider: TTSProvider, audioCache: AudioCacheManager) {
        self.provider = provider
        self.audioCache = audioCache
        setupAudioSession()
        setupRemoteCommands()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
    }
    
    public func play(sentences: [String], startingIndex: Int = 0) async {
        guard startingIndex < sentences.count else { return }
        state = .loading(sentenceIndex: startingIndex)
        
        do {
            // Synthesize current sentence
            let url = try await provider.synthesize(text: sentences[startingIndex])
            state = .playing(sentenceIndex: startingIndex)
            try await provider.play(audioURL: url)
            
            // Prefetch next sentence logic goes here
            
        } catch {
            state = .error(error.localizedDescription)
            // Fallback logic to AppleAVSpeechProvider on network fail
        }
    }
    
    public func pause() {
        provider.pause()
        if case .playing(let idx) = state {
            state = .paused(sentenceIndex: idx)
        }
    }
    
    public func resume() {
        provider.resume()
        if case .paused(let idx) = state {
            state = .playing(sentenceIndex: idx)
        }
    }
    
    public func stop() {
        provider.stop()
        state = .idle
    }
}
