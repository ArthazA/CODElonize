//
//  ConquestSystem.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import os

/// The result of processing a quiz attempt for area conquest.
enum ConquestResult: Equatable {
    /// The player conquered a previously unowned area.
    case firstClaim(playerID: String)
    
    /// The player took ownership from the previous owner by having a faster time.
    case conquered(newOwnerID: String, previousOwnerID: String)
    
    /// The current owner defended their area (the new attempt wasn't faster).
    case defended(ownerID: String)
    
    /// Whether ownership changed as a result of this attempt.
    var ownershipChanged: Bool {
        switch self {
        case .firstClaim, .conquered:
            return true
        case .defended:
            return false
        }
    }
    
    /// The player ID of the current owner after this result.
    var currentOwnerID: String {
        switch self {
        case .firstClaim(let playerID):
            return playerID
        case .conquered(let newOwnerID, _):
            return newOwnerID
        case .defended(let ownerID):
            return ownerID
        }
    }
}

/// Pure ownership comparison logic for area conquest.
///
/// `ConquestSystem` examines all recorded attempts for an area and determines
/// who should own it based on the fastest completion time.
/// It does not modify state directly — it returns results that the caller
/// (typically `MatchManager`) uses to update `GameState`.
enum ConquestSystem {
    
    /// Processes a completed quiz attempt and determines the conquest result.
    ///
    /// This is the main entry point. It:
    /// 1. Records the attempt via `AreaManager`
    /// 2. Evaluates ownership based on all attempts
    /// 3. Updates the area's owner and best time in `GameState`
    /// 4. Returns the result for UI/networking to react to
    ///
    /// - Parameters:
    ///   - areaIndex: The area that was attempted.
    ///   - playerID: The player who completed the quiz.
    ///   - time: The completion time in seconds.
    ///   - gameState: The game state to read from and modify.
    /// - Returns: The conquest result describing what happened.
    static func processAttemptResult(
        areaIndex: Int,
        playerID: String,
        time: TimeInterval,
        gameState: GameState
    ) -> ConquestResult {
        // Record the attempt
        AreaManager.recordAttempt(areaIndex: areaIndex, playerID: playerID, time: time, gameState: gameState)
        
        // Evaluate who should own this area now
        let previousOwnerID = gameState.areas[areaIndex].ownerID
        let (newOwnerID, newBestTime) = evaluateOwnership(for: gameState.areas[areaIndex])
        
        // Update area state
        gameState.areas[areaIndex].ownerID = newOwnerID
        gameState.areas[areaIndex].bestTime = newBestTime
        
        // Update conquered area counts for all players
        updateConqueredCounts(gameState: gameState)
        
        // Determine the result type
        let result: ConquestResult
        
        if let previousOwner = previousOwnerID {
            if newOwnerID == previousOwner {
                result = .defended(ownerID: previousOwner)
            } else {
                result = .conquered(newOwnerID: newOwnerID!, previousOwnerID: previousOwner)
            }
        } else {
            result = .firstClaim(playerID: newOwnerID!)
        }
        
        AppLogger.gameplay.info("Conquest result for area \(areaIndex): \(String(describing: result))")
        
        return result
    }
    
    /// Evaluates who should own an area based on all recorded attempts.
    ///
    /// The player with the fastest completion time becomes the owner.
    /// In case of identical times (EC-009), the first recorded attempt wins.
    ///
    /// - Parameter area: The area to evaluate.
    /// - Returns: A tuple of (ownerID, bestTime), or (nil, nil) if no attempts recorded.
    static func evaluateOwnership(for area: Area) -> (ownerID: String?, bestTime: TimeInterval?) {
        guard !area.attemptRecords.isEmpty else {
            return (nil, nil)
        }
        
        // Find the player with the fastest time
        // In case of ties (EC-009), the iteration order of Dictionary determines
        // the winner, which effectively means first-recorded wins.
        var bestPlayerID: String?
        var bestTime: TimeInterval = .infinity
        
        for (playerID, time) in area.attemptRecords {
            if time < bestTime {
                bestTime = time
                bestPlayerID = playerID
            }
        }
        
        return (bestPlayerID, bestTime)
    }
    
    /// Recalculates the `conqueredAreaCount` for every player based on current area ownership.
    ///
    /// - Parameter gameState: The game state to update.
    static func updateConqueredCounts(gameState: GameState) {
        // Reset all counts
        for i in 0..<gameState.players.count {
            gameState.players[i].conqueredAreaCount = 0
        }
        
        // Count owned areas
        for area in gameState.areas {
            if let ownerID = area.ownerID,
               let playerIdx = gameState.playerIndex(byID: ownerID) {
                gameState.players[playerIdx].conqueredAreaCount += 1
            }
        }
    }
}
