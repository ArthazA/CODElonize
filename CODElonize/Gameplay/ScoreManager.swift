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
    let playerID: String
    
    /// The player's display name.
    let displayName: String
    
    /// Number of areas currently owned by this player.
    let conqueredAreas: Int
    
    /// Total completion time across all attempted areas (tiebreaker).
    let totalTime: TimeInterval
    
    /// Identifiable conformance.
    var id: String { playerID }
}

/// The final match result, containing the winner and full leaderboard.
struct MatchResult: Equatable {
    /// The winning player's score, or nil if no winner (e.g. no conquests).
    let winner: PlayerScore?
    
    /// All players sorted by rank (most areas → least total time).
    let leaderboard: [PlayerScore]
}

/// Calculates scores and determines the match winner.
///
/// Winner rule (EC-028): Most conquered areas wins.
/// Tiebreaker: Lowest total completion time.
enum ScoreManager {
    
    /// Calculates the sorted leaderboard from the current game state.
    ///
    /// Players are sorted by:
    /// 1. Most conquered areas (descending)
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
                totalTime: player.totalCompletionTime
            )
        }
        
        // Sort: most areas first, then least total time
        return scores.sorted { a, b in
            if a.conqueredAreas != b.conqueredAreas {
                return a.conqueredAreas > b.conqueredAreas
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
                "Match result: winner='\(winner.displayName)' with \(winner.conqueredAreas) areas, time=\(String(format: "%.1f", winner.totalTime))s"
            )
        } else {
            AppLogger.gameplay.info("Match result: no winner (no players)")
        }
        
        return MatchResult(winner: winner, leaderboard: leaderboard)
    }
}
