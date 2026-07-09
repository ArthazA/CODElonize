
import Foundation
import Combine
import os

enum ActivationResult: Equatable {

    case success(description: String)

    case failed(reason: String)
}

enum PowerUpManager {

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

    @discardableResult
    static func removeFromInventory(type: PowerUpType, playerID: UUID, gameState: GameState) -> Bool {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return false }

        if let itemIdx = gameState.players[playerIdx].inventory.firstIndex(of: type) {
            gameState.players[playerIdx].inventory.remove(at: itemIdx)
            return true
        }
        return false
    }

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

            return nil

        case .tsunami:

            return nil

        case .pocketWatch:

            guard area.isConquered else {
                return "Pocket Watch only works on conquered areas"
            }

            guard player.completionTimes[targetArea] != nil else {
                return "You haven't attempted this area"
            }
            return nil
        }
    }

    static func activateEarthquake(
        playerID: UUID,
        targetArea: Int,
        gameState: GameState
    ) -> ActivationResult {
        if let reason = validateActivation(type: .earthquake, playerID: playerID, targetArea: targetArea, gameState: gameState) {
            return .failed(reason: reason)
        }

        removeFromInventory(type: .earthquake, playerID: playerID, gameState: gameState)

        AreaManager.resetArea(index: targetArea, gameState: gameState)

        ConquestSystem.updateConqueredCounts(gameState: gameState)

        let topic = gameState.areas[targetArea].topic
        AppLogger.gameplay.info("Earthquake activated by '\(playerID)' on area \(targetArea) (\(topic))")

        return .success(description: "Earthquake hit \(topic)! Area reset.")
    }

    static func activateTsunami(
        playerID: UUID,
        targetArea: Int,
        gameState: GameState
    ) -> ActivationResult {
        if let reason = validateActivation(type: .tsunami, playerID: playerID, targetArea: targetArea, gameState: gameState) {
            return .failed(reason: reason)
        }

        removeFromInventory(type: .tsunami, playerID: playerID, gameState: gameState)

        AreaManager.lockArea(
            index: targetArea,
            duration: GameConstants.tsunamiLockDuration,
            gameState: gameState
        )

        let topic = gameState.areas[targetArea].topic
        AppLogger.gameplay.info("Tsunami activated by '\(playerID)' on area \(targetArea) (\(topic))")

        return .success(description: "Tsunami hit \(topic)! Area locked for \(Int(GameConstants.tsunamiLockDuration))s.")
    }

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

        removeFromInventory(type: .pocketWatch, playerID: playerID, gameState: gameState)

        let reduction = currentTime * Double(GameConstants.pocketWatchReduction)
        let newTime = currentTime - reduction

        gameState.players[playerIdx].completionTimes[targetArea] = newTime

        gameState.areas[targetArea].attemptRecords[playerID.uuidString] = newTime

        let (newOwnerID, newBestTime) = ConquestSystem.evaluateOwnership(for: gameState.areas[targetArea])
        let previousOwnerID = gameState.areas[targetArea].ownerID

        gameState.areas[targetArea].ownerID = newOwnerID
        gameState.areas[targetArea].bestTime = newBestTime

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
