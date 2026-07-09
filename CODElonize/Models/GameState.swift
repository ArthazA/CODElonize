
import Foundation
import Combine

class GameState: ObservableObject {

    @Published var areas: [Area] = []

    @Published var players: [Player] = []

    @Published var matchTimeRemaining: TimeInterval = GameConstants.matchDuration

    @Published var isMatchActive: Bool = false

    @Published var isMatchFinished: Bool = false

    @Published var isArmageddonActive: Bool = false

    var armageddonTriggered: Bool = false

    @Published var emberMothPoints: [UUID: Double] = [:]

    var localPlayerID: UUID = UUID()

    func player(byID id: UUID) -> Player? {
        players.first { $0.id == id }
    }

    func player(byID id: String) -> Player? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return player(byID: uuid)
    }

    func playerIndex(byID id: UUID) -> Int? {
        players.firstIndex { $0.id == id }
    }

    func playerIndex(byID id: String) -> Int? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return playerIndex(byID: uuid)
    }

    func area(byIndex index: Int) -> Area? {
        guard index >= 0 && index < areas.count else { return nil }
        return areas[index]
    }

    var localPlayer: Player? {
        player(byID: localPlayerID)
    }

    var localPlayerIDString: String {
        localPlayerID.uuidString
    }

    var conqueredAreaCount: Int {
        areas.filter { $0.isConquered }.count
    }

    var conqueredAvailableAreaCount: Int {
        areas.filter { $0.isConquered && !$0.isArmageddonLocked }.count
    }

    var allAvailableAreasConquered: Bool {
        let availableAreas = areas.filter { !$0.isArmageddonLocked }
        return !availableAreas.isEmpty && availableAreas.allSatisfy { $0.isConquered }
    }

    var allAreasConquered: Bool {
        let attemptableAreas = areas.filter { $0.isAvailable || $0.isConquered }
        return !attemptableAreas.isEmpty && attemptableAreas.allSatisfy { $0.isConquered }
    }

    func emberMothPointsFor(playerID: UUID) -> Double {
        emberMothPoints[playerID] ?? 0
    }

    func awardEmberMothPoints(playerID: UUID, points: Double = GameConstants.emberMothPoints) {
        emberMothPoints[playerID, default: 0] += points
    }

    func initializeMatch(players: [Player], localPlayerID: UUID) {
        self.players = players
        self.localPlayerID = localPlayerID
        self.areas = Area.createAllAreas()
        self.matchTimeRemaining = GameConstants.matchDuration
        self.isMatchActive = true
        self.isMatchFinished = false
        self.isArmageddonActive = false
        self.armageddonTriggered = false
        self.emberMothPoints = [:]
    }

    func reset() {
        areas = []
        players = []
        matchTimeRemaining = GameConstants.matchDuration
        isMatchActive = false
        isMatchFinished = false
        isArmageddonActive = false
        armageddonTriggered = false
        emberMothPoints = [:]
        localPlayerID = UUID()
    }
}
