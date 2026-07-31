import Foundation
import Combine
import AVFoundation
import MediaPlayer

@MainActor
public final class TTSManager: ObservableObject {
    @Published public private(set) var state: TTSState = .idle
    @Published public private(set) var currentSentenceIndex: Int?

    public var onSentenceChanged: ((Int) -> Void)?
    public var onPlaybackFinished: (() -> Void)?
    public var onPlaybackError: ((String) -> Void)?
    public var onNextSentence: (() -> Void)?
    public var onPreviousSentence: (() -> Void)?

    public var speakingRate: Float {
        get { provider.speakingRate }
        set { provider.speakingRate = min(max(newValue, 0.25), 0.65) }
    }

    private var provider: TTSProvider
    private let offlineProvider: TTSProvider
    private let audioCache: AudioCacheManager
    private var playbackTask: Task<Void, Never>?
    private var sentences: [String] = []
    private var interruptionObserver: NSObjectProtocol?
    private var wasPlayingBeforeInterruption = false
    private var nowPlayingTitle = "Light Novel"
    private var nowPlayingAuthor = ""
    private var nowPlayingChapter = ""

    public init(provider: TTSProvider, audioCache: AudioCacheManager) {
        self.provider = provider
        self.offlineProvider = AppleAVSpeechProvider()
        self.audioCache = audioCache
        setupAudioSession()
        setupRemoteCommands()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let userInfo = notification.userInfo
            let rawType = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let rawOptions = userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleInterruption(typeRawValue: rawType, optionsRawValue: rawOptions)
            }
        }
    }

    public func start(sentences: [String], startingIndex: Int = 0) {
        let validSentences = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !validSentences.isEmpty, validSentences.indices.contains(startingIndex) else {
            stop()
            return
        }

        playbackTask?.cancel()
        provider.stop()
        self.sentences = validSentences
        updateNowPlaying(elapsed: startingIndex)
        playbackTask = Task { [weak self] in
            await self?.playFromIndex(startingIndex)
        }
    }

    public func pause() {
        provider.pause()
        if case .playing(let index) = state {
            state = .paused(sentenceIndex: index)
            updateNowPlaying(elapsed: index)
        }
    }

    public func resume() {
        provider.resume()
        if case .paused(let index) = state {
            state = .playing(sentenceIndex: index)
            updateNowPlaying(elapsed: index)
        }
    }

    public func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        provider.stop()
        state = .idle
        currentSentenceIndex = nil
        updateNowPlaying(elapsed: 0)
    }

    private func playFromIndex(_ startIndex: Int) async {
        for index in startIndex..<sentences.count {
            guard !Task.isCancelled else { return }
            currentSentenceIndex = index
            onSentenceChanged?(index)
            updateNowPlaying(elapsed: index)
            state = .loading(sentenceIndex: index)

            do {
                state = .playing(sentenceIndex: index)
                try await provider.speak(text: sentences[index])
            } catch is CancellationError {
                return
            } catch {
                if provider.providerName != offlineProvider.providerName {
                    provider.stop()
                    provider = offlineProvider
                    do {
                        state = .playing(sentenceIndex: index)
                        try await provider.speak(text: sentences[index])
                        continue
                    } catch is CancellationError {
                        return
                    } catch {
                        state = .error(error.localizedDescription)
                        onPlaybackError?("Đã chuyển sang giọng đọc offline nhưng vẫn không thể đọc: \(error.localizedDescription)")
                        return
                    }
                }
                state = .error(error.localizedDescription)
                onPlaybackError?(error.localizedDescription)
                return
            }
        }

        guard !Task.isCancelled else { return }
        state = .idle
        onPlaybackFinished?()
    }

    public func configureNowPlaying(title: String, author: String?, chapter: String) {
        nowPlayingTitle = title
        nowPlayingAuthor = author ?? ""
        nowPlayingChapter = chapter
        updateNowPlaying(elapsed: currentSentenceIndex ?? 0)
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            state = .error("Không thể kích hoạt âm thanh: \(error.localizedDescription)")
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.resume() }
            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.onNextSentence?() }
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.onPreviousSentence?() }
            return .success
        }
    }

    private func updateNowPlaying(elapsed: Int) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = nowPlayingTitle
        info[MPMediaItemPropertyArtist] = nowPlayingAuthor
        info[MPMediaItemPropertyAlbumTitle] = nowPlayingChapter
        info[MPMediaItemPropertyPlaybackDuration] = Double(max(sentences.count, 1))
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(elapsed)
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlayingState ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func handleInterruption(typeRawValue: UInt?, optionsRawValue: UInt?) {
        guard let rawType = typeRawValue,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
        switch type {
        case .began:
            wasPlayingBeforeInterruption = isPlayingState
            if wasPlayingBeforeInterruption { pause() }
        case .ended:
            guard wasPlayingBeforeInterruption,
                  let rawOptions = optionsRawValue,
                  AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume) else { return }
            resume()
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    private var isPlayingState: Bool {
        if case .playing = state { return true }
        return false
    }
}
