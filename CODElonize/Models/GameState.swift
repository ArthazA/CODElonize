//
//  GameState.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine

/// The authoritative representation of the current match.
///
/// `GameState` is the single source of truth for all gameplay systems.
/// In the host-authoritative architecture, the host owns the master copy
/// and broadcasts changes to all clients.
///
/// This is an `ObservableObject` so that UI views can react to state changes.
class GameState: ObservableObject {
    
    /// The seven conquerable areas on the island.
    @Published var areas: [Area] = []
    
    /// All players participating in the match.
    @Published var players: [Player] = []
    
    /// Remaining match time in seconds (counts down from `GameConstants.matchDuration`).
    @Published var matchTimeRemaining: TimeInterval = GameConstants.matchDuration
    
    /// Whether the match is currently in progress.
    @Published var isMatchActive: Bool = false
    
    /// Whether the match has finished (timer expired or manual end).
    @Published var isMatchFinished: Bool = false
    
    /// Whether the Armageddon Phase has been triggered (final 60 seconds).
    /// Once triggered, the 7th area unlocks and an Ember Moth spawns.
    @Published var isArmageddonActive: Bool = false
    
    /// Whether the Armageddon Phase has already been triggered this match.
    /// Prevents double-triggering.
    var armageddonTriggered: Bool = false
    
    /// Ember Moth points collected by each player.
    /// Key: player UUID, Value: accumulated Ember Moth points.
    @Published var emberMothPoints: [UUID: Double] = [:]
    
    /// The ID of the local player on this device.
    var localPlayerID: UUID = UUID()
    
    // MARK: - Lookups
    
    /// Returns the player with the given ID, or nil if not found.
    func player(byID id: UUID) -> Player? {
        players.first { $0.id == id }
    }
    
    /// Overload that accepts a String player ID.
    func player(byID id: String) -> Player? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return player(byID: uuid)
    }
    
    /// Returns the index of the player with the given ID in the `players` array.
    func playerIndex(byID id: UUID) -> Int? {
        players.firstIndex { $0.id == id }
    }
    
    /// Overload that accepts a String player ID.
    func playerIndex(byID id: String) -> Int? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return playerIndex(byID: uuid)
    }
    
    /// Returns the area at the given index.
    func area(byIndex index: Int) -> Area? {
        guard index >= 0 && index < areas.count else { return nil }
        return areas[index]
    }
    
    /// The local player on this device.
    var localPlayer: Player? {
        player(byID: localPlayerID)
    }
    
    /// The local player's ID as a string (convenience for area records).
    var localPlayerIDString: String {
        localPlayerID.uuidString
    }
    
    /// The number of conquered areas across the island.
    var conqueredAreaCount: Int {
        areas.filter { $0.isConquered }.count
    }
    
    /// The number of available (non-Armageddon-locked) conquered areas.
    var conqueredAvailableAreaCount: Int {
        areas.filter { $0.isConquered && !$0.isArmageddonLocked }.count
    }
    
    /// Whether all available (non-Armageddon-locked) areas have been conquered.
    var allAvailableAreasConquered: Bool {
        let availableAreas = areas.filter { !$0.isArmageddonLocked }
        return !availableAreas.isEmpty && availableAreas.allSatisfy { $0.isConquered }
    }
    
    /// Whether all areas (including the unlocked Armageddon area) have been conquered.
    var allAreasConquered: Bool {
        let attemptableAreas = areas.filter { $0.isAvailable || $0.isConquered }
        return !attemptableAreas.isEmpty && attemptableAreas.allSatisfy { $0.isConquered }
    }
    
    /// Returns the Ember Moth points for a given player.
    func emberMothPointsFor(playerID: UUID) -> Double {
        emberMothPoints[playerID] ?? 0
    }
    
    /// Awards Ember Moth points to a player.
    func awardEmberMothPoints(playerID: UUID, points: Double = GameConstants.emberMothPoints) {
        emberMothPoints[playerID, default: 0] += points
    }
    
    // MARK: - Initialization
    
    /// Initializes the game state for a new match.
    ///
    /// - Parameters:
    ///   - players: The players participating in the match.
    ///   - localPlayerID: The ID of the player on this device.
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
    
    /// Resets the game state completely (e.g. when returning to home).
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
