import Foundation
import MediaPlayer
import Combine
import UIKit

@MainActor
public final class NowPlayingManager: ObservableObject {
    public static let shared = NowPlayingManager()
    
    private init() {}
    
    public func updateNowPlayingInfo(title: String, author: String?, chapter: String, duration: Double, elapsed: Double) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = author ?? "Unknown Author"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = chapter
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        // Use the system book icon when no novel artwork is available.
        if let image = UIImage(systemName: "book.closed") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    public func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
}