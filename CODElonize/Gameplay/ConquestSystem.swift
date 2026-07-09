
import Foundation
import os

enum ConquestResult: Equatable {

    case firstClaim(playerID: String)

    case conquered(newOwnerID: String, previousOwnerID: String)

    case defended(ownerID: String)

    var ownershipChanged: Bool {
        switch self {
        case .firstClaim, .conquered:
            return true
        case .defended:
            return false
        }
    }

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

enum ConquestSystem {

    static func processAttemptResult(
        areaIndex: Int,
        playerID: UUID,
        time: TimeInterval,
        gameState: GameState
    ) -> ConquestResult {

        AreaManager.recordAttempt(areaIndex: areaIndex, playerID: playerID, time: time, gameState: gameState)

        let previousOwnerID = gameState.areas[areaIndex].ownerID
        let (newOwnerID, newBestTime) = evaluateOwnership(for: gameState.areas[areaIndex])

        gameState.areas[areaIndex].ownerID = newOwnerID
        gameState.areas[areaIndex].bestTime = newBestTime

        updateConqueredCounts(gameState: gameState)

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

    static func evaluateOwnership(for area: Area) -> (ownerID: String?, bestTime: TimeInterval?) {
        guard !area.attemptRecords.isEmpty else {
            return (nil, nil)
        }

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

    static func updateConqueredCounts(gameState: GameState) {

        for i in 0..<gameState.players.count {
            gameState.players[i].conqueredAreaCount = 0
        }

        for area in gameState.areas {
            if let ownerIDString = area.ownerID,
               let ownerID = UUID(uuidString: ownerIDString),
               let playerIdx = gameState.playerIndex(byID: ownerID) {
                gameState.players[playerIdx].conqueredAreaCount += 1
            }
        }
    }
}
