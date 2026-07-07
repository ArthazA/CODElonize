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
    
    /// The six conquerable areas on the island.
    @Published var areas: [Area] = []
    
    /// All players participating in the match.
    @Published var players: [Player] = []
    
    /// Remaining match time in seconds (counts down from `GameConstants.matchDuration`).
    @Published var matchTimeRemaining: TimeInterval = GameConstants.matchDuration
    
    /// Whether the match is currently in progress.
    @Published var isMatchActive: Bool = false
    
    /// Whether the match has finished (timer expired or manual end).
    @Published var isMatchFinished: Bool = false
    
    /// The ID of the local player on this device.
    var localPlayerID: UUID = UUID()
    
    // MARK: - Lookups
    
    /// Returns the player with the given ID, or nil if not found.
    func player(byID id: UUID) -> Player? {
        players.first { $0.id == id }
    }
    
    /// Returns the index of the player with the given ID in the `players` array.
    func playerIndex(byID id: UUID) -> Int? {
        players.firstIndex { $0.id == id }
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
    
    /// The number of conquered areas across the island.
    var conqueredAreaCount: Int {
        areas.filter { $0.isConquered }.count
    }
    
    /// Whether all areas have been conquered.
    var allAreasConquered: Bool {
        conqueredAreaCount == GameConstants.areaCount
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
    }
    
    /// Resets the game state completely (e.g. when returning to home).
    func reset() {
        areas = []
        players = []
        matchTimeRemaining = GameConstants.matchDuration
        isMatchActive = false
        isMatchFinished = false
        localPlayerID = UUID()
    }
}
