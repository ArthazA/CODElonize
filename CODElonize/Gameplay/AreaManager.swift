
import Foundation
import os

enum AreaManager {

    static func canAttempt(areaIndex: Int, playerID: UUID, gameState: GameState) -> Bool {
        guard let area = gameState.area(byIndex: areaIndex) else {
            AppLogger.gameplay.error("Invalid area index: \(areaIndex)")
            return false
        }

        guard let player = gameState.player(byID: playerID) else {
            AppLogger.gameplay.error("Player not found: \(playerID)")
            return false
        }

        guard !area.isLocked else {
            AppLogger.gameplay.info("Area \(areaIndex) is locked")
            return false
        }

        guard !player.completedAreas.contains(areaIndex) else {
            AppLogger.gameplay.info("Player '\(playerID)' already attempted area \(areaIndex)")
            return false
        }

        guard !player.isAttemptingQuiz else {
            AppLogger.gameplay.info("Player '\(playerID)' is already in a quiz")
            return false
        }

        return true
    }

    static func beginAttempt(areaIndex: Int, playerID: UUID, gameState: GameState) {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return }

        gameState.players[playerIdx].currentAttemptArea = areaIndex

        AppLogger.gameplay.info("Player '\(playerID)' began attempt on area \(areaIndex)")
    }

    static func recordAttempt(areaIndex: Int, playerID: UUID, time: TimeInterval, gameState: GameState) {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return }
        guard areaIndex < gameState.areas.count else { return }

        gameState.players[playerIdx].completedAreas.insert(areaIndex)
        gameState.players[playerIdx].completionTimes[areaIndex] = time
        gameState.players[playerIdx].currentAttemptArea = nil

        gameState.areas[areaIndex].attemptRecords[playerID.uuidString] = time

        AppLogger.gameplay.info(
            "Recorded attempt: player='\(playerID)', area=\(areaIndex), time=\(String(format: "%.1f", time))s"
        )
    }

    static func cancelAttempt(playerID: UUID, gameState: GameState) {
        guard let playerIdx = gameState.playerIndex(byID: playerID) else { return }

        let areaIndex = gameState.players[playerIdx].currentAttemptArea
        gameState.players[playerIdx].currentAttemptArea = nil

        AppLogger.gameplay.info("Cancelled attempt: player='\(playerID)', area=\(String(describing: areaIndex))")
    }

    static func lockArea(index: Int, duration: TimeInterval, gameState: GameState) {
        guard index < gameState.areas.count else { return }

        gameState.areas[index].isLocked = true
        gameState.areas[index].lockRemainingTime = duration

        AppLogger.gameplay.info("Area \(index) locked for \(duration)s")
    }

    static func unlockArea(index: Int, gameState: GameState) {
        guard index < gameState.areas.count else { return }

        gameState.areas[index].isLocked = false
        gameState.areas[index].lockRemainingTime = 0

        AppLogger.gameplay.info("Area \(index) unlocked")
    }

    static func resetArea(index: Int, gameState: GameState) {
        guard index < gameState.areas.count else { return }

        let oldOwner = gameState.areas[index].ownerID

        gameState.areas[index].ownerID = nil
        gameState.areas[index].bestTime = nil
        gameState.areas[index].attemptRecords.removeAll()
        gameState.areas[index].questionSeed = Randomizer.generateSeed()

        for i in 0..<gameState.players.count {
            gameState.players[i].completedAreas.remove(index)
            gameState.players[i].completionTimes.removeValue(forKey: index)
        }

        AppLogger.gameplay.info(
            "Area \(index) reset (was owned by '\(oldOwner ?? "none")'). New seed generated."
        )
    }
}
