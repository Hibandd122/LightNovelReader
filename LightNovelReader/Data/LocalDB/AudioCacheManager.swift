import Foundation
import CryptoKit
import OSLog

public actor AudioCacheManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 300 * 1024 * 1024 // 300MB
    
    // Add dictionary to track in-flight downloads for prefetching
    private var downloadTasks: [String: Task<URL, Error>] = [:]
    private let logger = Logger(subsystem: "com.lightnovelreader", category: "audio-cache")
    
    public init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("TTS_Audio")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: cacheDirectory.path)
            } catch {
                logger.error("Could not create audio cache: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    public func cacheAudio(data: Data, for key: String) throws -> URL {
        let fileURL = cacheDirectory.appendingPathComponent(cacheFileName(for: key))
        try data.write(to: fileURL)
        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
        Task { await cleanCacheIfNeeded() }
        return fileURL
    }
    
    public func getAudio(for key: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent(cacheFileName(for: key))
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
            return fileURL
        }
        return nil
    }

    public func clearAll() {
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
    
    /// Prefetches audio by running a background task and storing it in memory/disk.
    public func prefetchAudio(key: String, downloadAction: @escaping () async throws -> URL) async {
        guard getAudio(for: key) == nil else { return } // Already cached
        guard downloadTasks[key] == nil else { return } // Already fetching
        
        let task = Task { () -> URL in
            let url = try await downloadAction()
            // Assume downloadAction saves to cache or we move it
            return url
        }
        
        downloadTasks[key] = task
        
        do {
            _ = try await task.value
        } catch {
            logger.error("Prefetch failed for \(key, privacy: .private): \(error.localizedDescription, privacy: .public)")
        }
        
        downloadTasks[key] = nil
    }
    
    private func cleanCacheIfNeeded() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else { return }
        
        var totalSize: Int64 = 0
        var fileStats = [(url: URL, date: Date, size: Int64)]()
        
        for file in files {
            guard let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                  let size = attrs[FileAttributeKey.size] as? Int64,
                  let date = attrs[FileAttributeKey.modificationDate] as? Date else { continue }
            
            totalSize += size
            fileStats.append((url: file, date: date, size: size))
        }
        
        if totalSize > maxCacheSize {
            fileStats.sort { $0.date < $1.date }
            for fileStat in fileStats {
                try? fileManager.removeItem(at: fileStat.url)
                totalSize -= fileStat.size
                if totalSize <= 300 * 1024 * 1024 {
                    break
                }
            }
        }
    }

    private func cacheFileName(for key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return "\(digest).audio"
    }
}