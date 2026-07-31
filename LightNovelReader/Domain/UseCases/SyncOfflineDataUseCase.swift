import Foundation
import OSLog

@MainActor
public protocol SyncOfflineDataUseCaseProtocol {
    func execute() async throws
    func resolveConflict(localRevision: String, remoteRevision: String) async -> Bool
}

@MainActor
public struct SyncOfflineDataUseCase: SyncOfflineDataUseCaseProtocol {
    private let syncManager: SyncManager
    private let logger = Logger(subsystem: "com.lightnovelreader", category: "sync")
    
    public init(syncManager: SyncManager) {
        self.syncManager = syncManager
    }
    
    public func execute() async throws {
        syncManager.triggerSync()
    }
    
    public func resolveConflict(localRevision: String, remoteRevision: String) async -> Bool {
        if localRevision == remoteRevision {
            return true // No conflict, safe to push
        }
        logger.warning("Revision conflict detected: local \(localRevision, privacy: .private), remote \(remoteRevision, privacy: .private)")
        return false // Conflict requires manual merge
    }
}