import Foundation
import SwiftData

@Model
public final class Chapter {
    @Attribute(.unique) public var id: String
    public var title: String
    public var content: String
    public var readingProgress: Float // 0.0 -> 1.0
    public var lastReadAt: Date?
    
    public var novel: Novel?
    
    @Relationship(deleteRule: .cascade, inverse: \Bookmark.chapter)
    public var bookmarks: [Bookmark]
    
    public init(id: String, title: String, content: String = "", readingProgress: Float = 0.0, lastReadAt: Date? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.readingProgress = readingProgress
        self.lastReadAt = lastReadAt
        self.bookmarks = []
    }
}
