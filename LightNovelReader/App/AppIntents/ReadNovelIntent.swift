import AppIntents
import SwiftUI

public struct ReadNovelIntent: AppIntent {
    public nonisolated static let title: LocalizedStringResource = "Read Novel"
    public nonisolated static let description = IntentDescription("Continues reading your most recent light novel or a specific one.")
    public nonisolated static let openAppWhenRun = true
    
    @Parameter(title: "Novel Title", description: "The title of the novel you want to read")
    public var novelTitle: String?
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(novelTitle, forKey: "pendingReadNovelTitle")
        if let novelTitle {
            return .result(dialog: "Đang mở \(novelTitle).")
        }
        return .result(dialog: "Đang mở truyện gần đây nhất.")
    }
}
