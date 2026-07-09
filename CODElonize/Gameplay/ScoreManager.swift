
import Foundation
import os

struct PlayerScore: Identifiable, Equatable {

    let playerID: UUID

    let displayName: String

    let conqueredAreas: Int

    let totalTime: TimeInterval

    let emberMothPoints: Double

    var totalPoints: Double {
        Double(conqueredAreas) + emberMothPoints
    }

    var id: UUID { playerID }
}

struct MatchResult: Equatable {

    let winner: PlayerScore?

    let leaderboard: [PlayerScore]
}

enum ScoreManager {

    static func calculateScores(gameState: GameState) -> [PlayerScore] {
        let scores = gameState.players.map { player in
            PlayerScore(
                playerID: player.id,
                displayName: player.displayName,
                conqueredAreas: player.conqueredAreaCount,
                totalTime: player.totalCompletionTime,
                emberMothPoints: gameState.emberMothPointsFor(playerID: player.id)
            )
        }

        return scores.sorted { a, b in
            if a.totalPoints != b.totalPoints {
                return a.totalPoints > b.totalPoints
            }
            return a.totalTime < b.totalTime
        }
    }

    static func determineResult(gameState: GameState) -> MatchResult {
        let leaderboard = calculateScores(gameState: gameState)
        let winner = leaderboard.first

        if let winner {
            AppLogger.gameplay.info(
                "Match result: winner='\(winner.displayName)' with \(String(format: "%.1f", winner.totalPoints)) points, time=\(String(format: "%.1f", winner.totalTime))s"
            )
        } else {
            AppLogger.gameplay.info("Match result: no winner (no players)")
        }

        return MatchResult(winner: winner, leaderboard: leaderboard)
    }
}
