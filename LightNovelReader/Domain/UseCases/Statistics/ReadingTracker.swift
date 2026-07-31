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
    private var modelContext: ModelContext?
    
    public init() {}
    
    public func startSession(context: ModelContext) {
        modelContext = context
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<ReadingSession>(predicate: #Predicate { $0.date == today })
        let session: ReadingSession
        let existingSessions = (try? context.fetch(descriptor)) ?? []
        if let existing = existingSessions.first {
            session = existing
        } else {
            session = ReadingSession(date: today)
            context.insert(session)
        }

        self.currentSession = session
        self.sessionStartTime = Date()
        try? context.save()
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
        try? modelContext?.save()
    }

    public func setListening(_ listening: Bool) {
        isListening = listening
    }
    
    public func addWordsRead(_ count: Int) {
        currentSession?.wordsRead += count
    }
    
    private func calculateStreak(context: ModelContext) {
        guard let sessions = try? context.fetch(FetchDescriptor<ReadingSession>(sortBy: [SortDescriptor(\ReadingSession.date, order: .reverse)])) else {
            currentStreak = 0
            return
        }
        let activeDays = Set(sessions.filter { $0.readingDuration + $0.listeningDuration > 0 }.map {
            Calendar.current.startOfDay(for: $0.date)
        })
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())
        while activeDays.contains(day) {
            streak += 1
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        currentStreak = streak
    }
}