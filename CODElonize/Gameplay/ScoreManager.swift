//
//  ScoreManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import os

/// A player's score summary for leaderboard display and winner determination.
struct PlayerScore: Identifiable, Equatable {
    /// The player's unique ID.
    let playerID: UUID
    
    /// The player's display name.
    let displayName: String
    
    /// Number of areas currently owned by this player.
    let conqueredAreas: Int
    
    /// Total completion time across all attempted areas (tiebreaker).
    let totalTime: TimeInterval
    
    /// Points from Ember Moth collections (each worth 0.5).
    let emberMothPoints: Double
    
    /// Total points: conqueredAreas × 1.0 + emberMothPoints.
    var totalPoints: Double {
        Double(conqueredAreas) + emberMothPoints
    }
    
    /// Identifiable conformance.
    var id: UUID { playerID }
}

/// The final match result, containing the winner and full leaderboard.
struct MatchResult: Equatable {
    /// The winning player's score, or nil if no winner (e.g. no conquests).
    let winner: PlayerScore?
    
    /// All players sorted by rank (most points → least total time).
    let leaderboard: [PlayerScore]
}

/// Calculates scores and determines the match winner.
///
/// Winner rule: Highest total points wins.
/// Points = (conquered areas × 1) + (Ember Moth collections × 0.5).
/// Tiebreaker: Lowest total completion time.
enum ScoreManager {
    
    /// Calculates the sorted leaderboard from the current game state.
    ///
    /// Players are sorted by:
    /// 1. Highest total points (descending)
    /// 2. Lowest total completion time (ascending, as tiebreaker)
    ///
    /// - Parameter gameState: The current game state.
    /// - Returns: An array of `PlayerScore` sorted by rank.
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
        
        // Sort: most points first, then least total time
        return scores.sorted { a, b in
            if a.totalPoints != b.totalPoints {
                return a.totalPoints > b.totalPoints
            }
            return a.totalTime < b.totalTime
        }
    }
    
    /// Determines the match winner and produces the final result.
    ///
    /// - Parameter gameState: The current game state.
    /// - Returns: A `MatchResult` with the winner and full leaderboard.
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
