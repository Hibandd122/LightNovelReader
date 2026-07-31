import Foundation
import SwiftData

@Model
public final class Note {
    @Attribute(.unique) public var id: UUID
    public var novelId: String
    public var chapterId: String?
    public var highlightedText: String
    public var noteContent: String
    public var locationRangeStart: Int
    public var locationRangeLength: Int
    public var hexColor: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), novelId: String, chapterId: String? = nil, highlightedText: String, noteContent: String, locationRangeStart: Int, locationRangeLength: Int, hexColor: String = "#FFEB3B", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.novelId = novelId
        self.chapterId = chapterId
        self.highlightedText = highlightedText
        self.noteContent = noteContent
        self.locationRangeStart = locationRangeStart
        self.locationRangeLength = locationRangeLength
        self.hexColor = hexColor
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public func exportAsMarkdown() -> String {
        return """
        > \(highlightedText)
        
        **Note:** \(noteContent)
        
        *Created at: \(createdAt)*
        ---
        """
    }
}
