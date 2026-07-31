import Foundation
import MediaPlayer
import Combine

@MainActor
public final class NowPlayingManager: ObservableObject {
    public static let shared = NowPlayingManager()
    
    private init() {
        setupRemoteCommandCenter()
    }
    
    public func updateNowPlayingInfo(title: String, author: String?, chapter: String, duration: Double, elapsed: Double) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = author ?? "Unknown Author"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = chapter
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        // Artwork dummy fallback
        if let image = UIImage(systemName: "book.closed") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    public func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { event in
            // Handle play
            // Need to route this back to TTSManager
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { event in
            // Handle pause
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { event in
            // Handle next sentence/chapter
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { event in
            // Handle previous sentence/chapter
            return .success
        }
    }
}
