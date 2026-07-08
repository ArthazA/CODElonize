//
//  AreaManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import os

/// Manages area state transitions: attempt eligibility, locking, and resets.
///
/// `AreaManager` operates on the `GameState` and enforces the rules about
/// when a player can attempt an area, when areas get locked, etc.
/// It does NOT determine ownership — that's `ConquestSystem`'s job.
enum AreaManager {
    
    // MARK: - Attempt Eligibility
    
    /// Checks whether a player can attempt the given area.
    ///
    /// A player can attempt an area if:
    /// - The area exists and is not locked
    /// - The player hasn't already attempted this area in the current match
    /// - The player is not currently in another quiz
    ///
    /// - Parameters:
    ///   - areaIndex: The area to check (0–5).
    ///   - playerID: The player requesting the attempt.
    ///   - gameState: The current game state.
    /// - Returns: `true` if the attempt is allowed.
    static func canAttempt(areaIndex: Int, playerID: UUID, gameState: GameState) -> Bool {
        guard let area = gameState.area(byIndex: areaIndex) else {
            AppLogger.gameplay.error("Invalid area index: \(areaIndex)")
            return false
        }
        
        guard let player = gameState.player(byID: playerID) else {
            AppLogger.gameplay.error("Player not found: \(playerID)")
            return false
        }
        
        // Check area availability
        guard !area.isLocked else {
            AppLogger.gameplay.info("Area \(areaIndex) is locked")
            return false
        }
        
        // Check if player already attempted this area
        guard !player.completedAreas.contains(areaIndex) else {
            AppLogger.gameplay.info("Player '\(playerID)' already attempted area \(areaIndex)")
            return false
        }
        
        // Check if player is currently in another quiz
        guard !player.isAttemptingQuiz else {
            AppLogger.gameplay.info("Player '\(playerID)' is already in a quiz")
            return false
        }
        
        return true
    }
    
    /// Marks a player as currently attempting an area.
    ///
    /// - Parameters:
    ///   - areaIndex: The area being attempted.
    ///   - playerID: The player starting the attempt.
    ///   - gameState: The game state to modify.
    static func beginAttempt(areaIndex: Int, playerID: UUID, gameState: GameState) {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return }
        
        gameState.players[playerIdx].currentAttemptArea = areaIndex
        
        AppLogger.gameplay.info("Player '\(playerID)' began attempt on area \(areaIndex)")
    }
    
    /// Records a completed attempt and clears the player's active attempt state.
    ///
    /// - Parameters:
    ///   - areaIndex: The area that was attempted.
    ///   - playerID: The player who completed the attempt.
    ///   - time: The completion time in seconds.
    ///   - gameState: The game state to modify.
    static func recordAttempt(areaIndex: Int, playerID: UUID, time: TimeInterval, gameState: GameState) {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return }
        guard areaIndex < gameState.areas.count else { return }
        
        // Record in player state
        gameState.players[playerIdx].completedAreas.insert(areaIndex)
        gameState.players[playerIdx].completionTimes[areaIndex] = time
        gameState.players[playerIdx].currentAttemptArea = nil
        
        // Record in area state
        gameState.areas[areaIndex].attemptRecords[playerID.uuidString] = time
        
        AppLogger.gameplay.info(
            "Recorded attempt: player='\(playerID)', area=\(areaIndex), time=\(String(format: "%.1f", time))s"
        )
    }
    
    /// Cancels a player's current attempt without recording it.
    /// The attempt is NOT consumed — the player can retry later (EC-010).
    ///
    /// - Parameters:
    ///   - playerID: The player whose attempt to cancel.
    ///   - gameState: The game state to modify.
    static func cancelAttempt(playerID: UUID, gameState: GameState) {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return }
        
        let areaIndex = gameState.players[playerIdx].currentAttemptArea
        gameState.players[playerIdx].currentAttemptArea = nil
        
        AppLogger.gameplay.info("Cancelled attempt: player='\(playerID)', area=\(String(describing: areaIndex))")
    }
    
    // MARK: - Area Locking (Tsunami)
    
    /// Locks an area, making it unavailable for attempts.
    ///
    /// - Parameters:
    ///   - index: The area to lock.
    ///   - duration: Lock duration in seconds.
    ///   - gameState: The game state to modify.
    static func lockArea(index: Int, duration: TimeInterval, gameState: GameState) {
        guard index < gameState.areas.count else { return }
        
        gameState.areas[index].isLocked = true
        gameState.areas[index].lockRemainingTime = duration
        
        AppLogger.gameplay.info("Area \(index) locked for \(duration)s")
    }
    
    /// Unlocks an area, making it available for attempts again.
    ///
    /// - Parameters:
    ///   - index: The area to unlock.
    ///   - gameState: The game state to modify.
    static func unlockArea(index: Int, gameState: GameState) {
        guard index < gameState.areas.count else { return }
        
        gameState.areas[index].isLocked = false
        gameState.areas[index].lockRemainingTime = 0
        
        AppLogger.gameplay.info("Area \(index) unlocked")
    }
    
    // MARK: - Area Reset (Earthquake)
    
    /// Resets an area: clears owner, all attempt records, and generates new questions.
    ///
    /// - Parameters:
    ///   - index: The area to reset.
    ///   - gameState: The game state to modify.
    static func resetArea(index: Int, gameState: GameState) {
        guard index < gameState.areas.count else { return }
        
        let oldOwner = gameState.areas[index].ownerID
        
        // Clear area state
        gameState.areas[index].ownerID = nil
        gameState.areas[index].bestTime = nil
        gameState.areas[index].attemptRecords.removeAll()
        gameState.areas[index].questionSeed = Randomizer.generateSeed()
        
        // Clear all players' records for this area so they can re-attempt
        for i in 0..<gameState.players.count {
            gameState.players[i].completedAreas.remove(index)
            gameState.players[i].completionTimes.removeValue(forKey: index)
        }
        
        AppLogger.gameplay.info(
            "Area \(index) reset (was owned by '\(oldOwner ?? "none")'). New seed generated."
        )
    }
}
