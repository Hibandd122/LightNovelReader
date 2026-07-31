import Foundation
import SwiftData

@Model
public final class Novel {
    @Attribute(.unique) public var id: String
    public var title: String
    public var author: String?
    public var coverURL: String?
    public var lastModified: Date
    public var syncStatus: Int // 0: Synced, 1: Pending
    
    @Relationship(deleteRule: .cascade, inverse: \Chapter.novel)
    public var chapters: [Chapter]
    
    public init(id: String, title: String, author: String? = nil, coverURL: String? = nil, lastModified: Date = Date(), syncStatus: Int = 0) {
        self.id = id
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.lastModified = lastModified
        self.syncStatus = syncStatus
        self.chapters = []
    }
}
