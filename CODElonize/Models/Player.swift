//
//  Player.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

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
    
    /// Power-ups the player has collected but not yet activated.
    /// Maximum size is `GameConstants.maxInventorySize`.
    var inventory: [PowerUpType] = []
    
    // MARK: - Computed Properties
    
    /// Number of areas this player currently owns.
    /// Computed externally by checking `GameState.areas` since ownership
    /// depends on best-time comparison across all players.
    /// This is a convenience for quick access when the caller doesn't
    /// have the full game state.
    var conqueredAreaCount: Int = 0

    var totalCompletionTime: TimeInterval {
        completionTimes.values.reduce(0, +)
    }

    var isAttemptingQuiz: Bool {
        currentAttemptArea != nil
    }

    var displayName: String { name }
}
