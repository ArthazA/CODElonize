
import Foundation

struct Player: Codable, Identifiable {
    let id: UUID
    var name: String
    var avatar: String = "player_1" 
    var isHost: Bool
    var isReady: Bool

    var completedAreas: Set<Int> = []
    var completionTimes: [Int: TimeInterval] = [:]
    var currentAttemptArea: Int? = nil

    var inventory: [PowerUpType] = []

    var conqueredAreaCount: Int = 0

    var totalCompletionTime: TimeInterval {
        completionTimes.values.reduce(0, +)
    }

    var isAttemptingQuiz: Bool {
        currentAttemptArea != nil
    }

    var displayName: String { name }
}
