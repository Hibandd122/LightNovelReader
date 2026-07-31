import Foundation
import SwiftData
import SwiftUI

@Model
public final class Bookmark {
    @Attribute(.unique) public var id: UUID
    public var novelId: String
    public var chapterId: String?
    public var locationIndex: Int
    public var title: String
    public var folderName: String // Added Folder support
    public var tag: String? // Added Tag support
    public var hexColor: String // Added Color support
    public var createdAt: Date
    public var syncedToCloud: Bool
    
    public init(id: UUID = UUID(), novelId: String, chapterId: String? = nil, locationIndex: Int, title: String, folderName: String = "Default", tag: String? = nil, hexColor: String = "#FFCC00", createdAt: Date = Date(), syncedToCloud: Bool = false) {
        self.id = id
        self.novelId = novelId
        self.chapterId = chapterId
        self.locationIndex = locationIndex
        self.title = title
        self.folderName = folderName
        self.tag = tag
        self.hexColor = hexColor
        self.createdAt = createdAt
        self.syncedToCloud = syncedToCloud
    }
}
