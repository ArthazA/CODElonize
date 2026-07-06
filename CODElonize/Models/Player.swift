//
//  Player.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

/// Represents a player participating in a match.
///
/// Each player has a unique ID, tracks which areas they've attempted,
/// and stores their recorded completion times for ownership comparison.
struct Player: Identifiable, Equatable {
    
    /// Unique identifier for this player (typically the device peer ID).
    let id: String
    
    /// The player's chosen display name.
    var displayName: String
    
    /// Area indices (0–5) that this player has already attempted.
    /// Each area can only be attempted once per match.
    var completedAreas: Set<Int> = []
    
    /// Recorded completion times for each attempted area.
    /// Key: area index (0–5), Value: completion time in seconds.
    var completionTimes: [Int: TimeInterval] = [:]
    
    /// The area index the player is currently attempting (nil if not in a quiz).
    var currentAttemptArea: Int? = nil
    
    // MARK: - Computed Properties
    
    /// Number of areas this player currently owns.
    /// Computed externally by checking `GameState.areas` since ownership
    /// depends on best-time comparison across all players.
    /// This is a convenience for quick access when the caller doesn't
    /// have the full game state.
    var conqueredAreaCount: Int = 0
    
    /// Total completion time across all attempted areas.
    /// Used as a tiebreaker when two players own the same number of areas (EC-028).
    var totalCompletionTime: TimeInterval {
        completionTimes.values.reduce(0, +)
    }
    
    /// Whether this player is currently attempting a quiz.
    var isAttemptingQuiz: Bool {
        currentAttemptArea != nil
    }
}
