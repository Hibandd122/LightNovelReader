import AppIntents
import SwiftUI

public struct ReadNovelIntent: AppIntent {
    public nonisolated static let title: LocalizedStringResource = "Read Novel"
    public nonisolated static let description = IntentDescription("Continues reading your most recent light novel or a specific one.")
    
    @Parameter(title: "Novel Title", description: "The title of the novel you want to read")
    public var novelTitle: String?
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        // Find novel in SwiftData context based on novelTitle or fallback to most recent
        // Tell TTSManager to resume playing
        
        // This runs in the background. If we want to open the app, we can use `openAppWhenRun = true`
        
        return .result(dialog: "Resuming your light novel.")
    }
}
