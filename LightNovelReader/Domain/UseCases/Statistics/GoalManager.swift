import Foundation
import Combine

public struct ReadingGoal: Equatable {
    public var targetMinutesPerDay: Int
    public var targetWordsPerDay: Int
    public var targetChaptersPerDay: Int
}

@MainActor
public final class GoalManager: ObservableObject {
    @Published public var currentGoal: ReadingGoal
    @Published public var minutesCompleted: Int = 0
    @Published public var wordsCompleted: Int = 0
    
    public init() {
        // Load from UserDefaults or SwiftData
        self.currentGoal = ReadingGoal(targetMinutesPerDay: 30, targetWordsPerDay: 5000, targetChaptersPerDay: 1)
    }
    
    public func updateProgress(session: ReadingSession) {
        self.minutesCompleted = Int((session.readingDuration + session.listeningDuration) / 60)
        self.wordsCompleted = session.wordsRead
    }
    
    public func setGoal(_ goal: ReadingGoal) {
        self.currentGoal = goal
        // Save to persistent storage
    }
    
    public var isMinutesGoalReached: Bool {
        return minutesCompleted >= currentGoal.targetMinutesPerDay
    }
    
    public var isWordsGoalReached: Bool {
        return wordsCompleted >= currentGoal.targetWordsPerDay
    }
}
