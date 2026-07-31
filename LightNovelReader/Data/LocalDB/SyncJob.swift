import Foundation
import SwiftData

@Model
public final class SyncJob {
    @Attribute(.unique) public var id: UUID
    public var documentId: String
    public var operationType: Int // 0: editContent, 1: updateProgress, 2: addBookmark
    public var payload: Data
    public var status: Int // 0: pending, 1: inProgress, 2: failed, 3: conflict awaiting manual resolution
    public var retryCount: Int
    public var nextAttemptAt: Date?
    public var createdAt: Date
    
    public init(id: UUID = UUID(), documentId: String, operationType: Int, payload: Data, status: Int = 0, retryCount: Int = 0, nextAttemptAt: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.documentId = documentId
        self.operationType = operationType
        self.payload = payload
        self.status = status
        self.retryCount = retryCount
        self.nextAttemptAt = nextAttemptAt
        self.createdAt = createdAt
    }
}