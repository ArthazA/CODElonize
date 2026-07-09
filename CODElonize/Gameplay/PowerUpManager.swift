//
//  PowerUpManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine
import os

/// The result of attempting to activate a power-up.
enum ActivationResult: Equatable {
    /// Power-up activated successfully.
    case success(description: String)
    /// Activation failed (reason provided for UI feedback).
    case failed(reason: String)
}

/// Manages power-up collection, inventory, and activation effects.
///
/// `PowerUpManager` contains the core logic for all three power-up effects:
/// - **Earthquake**: Resets area (owner, times, questions)
/// - **Tsunami**: Locks area, kicks active players
/// - **Pocket Watch**: Reduces player's time by 10%, re-evaluates ownership
///
/// It operates on `GameState` and calls into `AreaManager`/`ConquestSystem`
/// for the actual state mutations.
enum PowerUpManager {
    
    // MARK: - Collection
    
    /// Adds a collected power-up to a player's inventory.
    ///
    /// - Parameters:
    ///   - type: The type of power-up collected.
    ///   - playerID: The collecting player's ID.
    ///   - gameState: The game state to modify.
    /// - Returns: `true` if the power-up was added to inventory.
    @discardableResult
    static func addToInventory(type: PowerUpType, playerID: UUID, gameState: GameState) -> Bool {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else {
            AppLogger.gameplay.error("Player not found for inventory: \(playerID)")
            return false
        }
        
        guard gameState.players[playerIdx].inventory.count < GameConstants.maxInventorySize else {
            AppLogger.gameplay.info("Inventory full for player '\(playerID)'")
            return false
        }
        
        gameState.players[playerIdx].inventory.append(type)
        AppLogger.gameplay.info("Added \(type.rawValue) to '\(playerID)' inventory")
        return true
    }
    
    /// Removes a power-up from a player's inventory (consumed on activation).
    ///
    /// - Parameters:
    ///   - type: The type of power-up to remove.
    ///   - playerID: The player's ID.
    ///   - gameState: The game state to modify.
    /// - Returns: `true` if the power-up was found and removed.
    @discardableResult
    static func removeFromInventory(type: PowerUpType, playerID: UUID, gameState: GameState) -> Bool {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return false }
        
        if let itemIdx = gameState.players[playerIdx].inventory.firstIndex(of: type) {
            gameState.players[playerIdx].inventory.remove(at: itemIdx)
            return true
        }
        return false
    }
    
    // MARK: - Validation
    
    /// Checks whether a power-up can be activated on a target area.
    ///
    /// - Parameters:
    ///   - type: The power-up type to validate.
    ///   - playerID: The activating player's ID.
    ///   - targetArea: The target area index.
    ///   - gameState: The current game state.
    /// - Returns: `nil` if activation is valid, or a failure reason string.
    static func validateActivation(
        type: PowerUpType,
        playerID: UUID,
        targetArea: Int,
        gameState: GameState
    ) -> String? {
        guard let player = gameState.player(byID: playerID) else {
            return "Player not found"
        }
        
        guard player.inventory.contains(type) else {
            return "Power-up not in inventory"
        }
        
        guard let area = gameState.area(byIndex: targetArea) else {
            return "Invalid area"
        }
        
        switch type {
        case .earthquake:
            // Earthquake works on any area (EC-022: even unconquered)
            return nil
            
        case .tsunami:
            // Tsunami works on any area (EC-023: even already locked — renews timer)
            return nil
            
        case .pocketWatch:
            // Must be a conquered area (EC-025: nothing happens on unconquered)
            guard area.isConquered else {
                return "Pocket Watch only works on conquered areas"
            }
            // Player must have a recorded time for this area
            guard player.completionTimes[targetArea] != nil else {
                return "You haven't attempted this area"
            }
            return nil
        }
    }
    
    // MARK: - Activation Effects
    
    /// Activates an Earthquake power-up on the target area.
    ///
    /// Effects (EC-022 compatible):
    /// - Clears the area owner
    /// - Removes all recorded completion times
    /// - Generates a new question seed
    /// - All players can re-attempt the area
    ///
    /// - Parameters:
    ///   - playerID: The activating player's ID.
    ///   - targetArea: The area to earthquake.
    ///   - gameState: The game state to modify.
    /// - Returns: The activation result.
    static func activateEarthquake(
        playerID: UUID,
        targetArea: Int,
        gameState: GameState
    ) -> ActivationResult {
        if let reason = validateActivation(type: .earthquake, playerID: playerID, targetArea: targetArea, gameState: gameState) {
            return .failed(reason: reason)
        }
        
        // Consume the power-up
        removeFromInventory(type: .earthquake, playerID: playerID, gameState: gameState)
        
        // Apply effect
        AreaManager.resetArea(index: targetArea, gameState: gameState)
        
        // Recalculate conquered counts
        ConquestSystem.updateConqueredCounts(gameState: gameState)
        
        let topic = gameState.areas[targetArea].topic
        AppLogger.gameplay.info("Earthquake activated by '\(playerID)' on area \(targetArea) (\(topic))")
        
        return .success(description: "Earthquake hit \(topic)! Area reset.")
    }
    
    /// Activates a Tsunami power-up on the target area.
    ///
    /// Effects (EC-023 compatible):
    /// - Locks the area for `tsunamiLockDuration` seconds
    /// - If already locked, renews the lock timer
    /// - Players currently attempting this area have their quiz cancelled
    ///
    /// - Parameters:
    ///   - playerID: The activating player's ID.
    ///   - targetArea: The area to tsunami.
    ///   - gameState: The game state to modify.
    /// - Returns: The activation result.
    static func activateTsunami(
        playerID: UUID,
        targetArea: Int,
        gameState: GameState
    ) -> ActivationResult {
        if let reason = validateActivation(type: .tsunami, playerID: playerID, targetArea: targetArea, gameState: gameState) {
            return .failed(reason: reason)
        }
        
        // Consume the power-up
        removeFromInventory(type: .tsunami, playerID: playerID, gameState: gameState)
        
        // Lock the area (renews if already locked per EC-023)
        AreaManager.lockArea(
            index: targetArea,
            duration: GameConstants.tsunamiLockDuration,
            gameState: gameState
        )
        
        let topic = gameState.areas[targetArea].topic
        AppLogger.gameplay.info("Tsunami activated by '\(playerID)' on area \(targetArea) (\(topic))")
        
        return .success(description: "Tsunami hit \(topic)! Area locked for \(Int(GameConstants.tsunamiLockDuration))s.")
    }
    
    /// Activates a Pocket Watch power-up on the target area.
    ///
    /// Effects (EC-024, EC-025 compatible):
    /// - Reduces the activating player's recorded time by 10%
    /// - Re-evaluates ownership — may change owner if adjusted time is fastest
    /// - Does nothing on unconquered areas (EC-025)
    ///
    /// - Parameters:
    ///   - playerID: The activating player's ID.
    ///   - targetArea: The area to adjust.
    ///   - gameState: The game state to modify.
    /// - Returns: The activation result.
    static func activatePocketWatch(
        playerID: UUID,
        targetArea: Int,
        gameState: GameState
    ) -> ActivationResult {
        if let reason = validateActivation(type: .pocketWatch, playerID: playerID, targetArea: targetArea, gameState: gameState) {
            return .failed(reason: reason)
        }
        
        guard let playerIdx = gameState.playerIndex(byID: playerID) else {
            return .failed(reason: "Player not found")
        }
        
        guard let currentTime = gameState.players[playerIdx].completionTimes[targetArea] else {
            return .failed(reason: "No recorded time for this area")
        }
        
        // Consume the power-up
        removeFromInventory(type: .pocketWatch, playerID: playerID, gameState: gameState)
        
        // Reduce time by 10%
        let reduction = currentTime * Double(GameConstants.pocketWatchReduction)
        let newTime = currentTime - reduction
        
        // Update player's recorded time
        gameState.players[playerIdx].completionTimes[targetArea] = newTime
        
        // Update the area's attempt record
        gameState.areas[targetArea].attemptRecords[playerID.uuidString] = newTime
        
        // Re-evaluate ownership
        let (newOwnerID, newBestTime) = ConquestSystem.evaluateOwnership(for: gameState.areas[targetArea])
        let previousOwnerID = gameState.areas[targetArea].ownerID
        
        gameState.areas[targetArea].ownerID = newOwnerID
        gameState.areas[targetArea].bestTime = newBestTime
        
        // Update conquered counts
        ConquestSystem.updateConqueredCounts(gameState: gameState)
        
        let ownershipChanged = newOwnerID != previousOwnerID
        let topic = gameState.areas[targetArea].topic
        
        AppLogger.gameplay.info(
            "Pocket Watch activated by '\(playerID)' on area \(targetArea): \(String(format: "%.1f", currentTime))s → \(String(format: "%.1f", newTime))s. Ownership changed: \(ownershipChanged)"
        )
        
        if ownershipChanged {
            return .success(description: "Pocket Watch used on \(topic)! You're now the fastest — area conquered!")
        } else {
            return .success(description: "Pocket Watch used on \(topic)! Time reduced to \(String(format: "%.1f", newTime))s.")
        }
    }
}
