import Foundation
import Combine
import SwiftData

@Model
public final class ReadingSession {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var readingDuration: TimeInterval // In seconds
    public var listeningDuration: TimeInterval
    public var wordsRead: Int
    
    public init(id: UUID = UUID(), date: Date = Date(), readingDuration: TimeInterval = 0, listeningDuration: TimeInterval = 0, wordsRead: Int = 0) {
        self.id = id
        self.date = date
        self.readingDuration = readingDuration
        self.listeningDuration = listeningDuration
        self.wordsRead = wordsRead
    }
}

@MainActor
public final class ReadingTracker: ObservableObject {
    @Published public var currentSession: ReadingSession?
    @Published public var currentStreak: Int = 0
    
    private var sessionStartTime: Date?
    private var isListening: Bool = false
    
    public init() {}
    
    public func startSession(context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch session for today or create new
        // Normally done with FetchDescriptor in SwiftData
        let newSession = ReadingSession(date: today)
        context.insert(newSession)
        
        self.currentSession = newSession
        self.sessionStartTime = Date()
        
        calculateStreak(context: context)
    }
    
    public func stopSession() {
        guard let startTime = sessionStartTime, let session = currentSession else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        if isListening {
            session.listeningDuration += duration
        } else {
            session.readingDuration += duration
        }
        
        self.sessionStartTime = nil
    }
    
    public func addWordsRead(_ count: Int) {
        currentSession?.wordsRead += count
    }
    
    private func calculateStreak(context: ModelContext) {
        // Fetch all ReadingSessions, sort by date descending.
        // Count consecutive days where readingDuration + listeningDuration > 0
        // Update self.currentStreak
        self.currentStreak = 1 // Mock implementation
    }
}
