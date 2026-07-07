//
//  SpawnManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine
import os

/// Manages the random spawning of power-ups during a match.
///
/// `SpawnManager` runs a recurring timer that spawns power-ups at random intervals
/// (15–45 seconds) at predefined spawn slot positions around the island.
/// It enforces a maximum of `GameConstants.maxActivePowerUps` uncollected power-ups
/// on the island at any time.
class SpawnManager: ObservableObject {
    
    /// All spawned power-ups (both collected and uncollected).
    @Published var spawnedPowerUps: [SpawnedPowerUp] = []
    
    /// Whether spawning is currently active.
    private(set) var isSpawning: Bool = false
    
    /// Timer for the next spawn.
    private var spawnTimer: AnyCancellable?
    
    /// Tracks which spawn slots are currently occupied by uncollected power-ups.
    private var occupiedSlots: Set<Int> = []
    
    // MARK: - Computed Properties
    
    /// Power-ups that are currently on the island (uncollected).
    var activePowerUps: [SpawnedPowerUp] {
        spawnedPowerUps.filter { !$0.isCollected }
    }
    
    /// Whether the island can accept more spawns.
    var canSpawn: Bool {
        activePowerUps.count < GameConstants.maxActivePowerUps
    }
    
    // MARK: - Spawn Control
    
    /// Starts the random spawn timer.
    func startSpawning() {
        guard !isSpawning else { return }
        isSpawning = true
        scheduleNextSpawn()
        
        AppLogger.gameplay.info("Power-up spawning started")
    }
    
    /// Stops the spawn timer and clears all spawns.
    func stopSpawning() {
        spawnTimer?.cancel()
        spawnTimer = nil
        isSpawning = false
        
        AppLogger.gameplay.info("Power-up spawning stopped")
    }
    
    /// Resets all spawns (used when match ends or resets).
    func reset() {
        stopSpawning()
        spawnedPowerUps.removeAll()
        occupiedSlots.removeAll()
    }
    
    // MARK: - Forced Spawns
    
    /// Forces an Earthquake power-up to spawn immediately.
    /// Called when all areas are conquered (EC-026).
    func spawnEarthquake() {
        spawnPowerUp(ofType: .earthquake)
        AppLogger.gameplay.info("Forced Earthquake spawn (all areas conquered)")
    }
    
    // MARK: - Collection
    
    /// Marks a power-up as collected and frees its spawn slot.
    ///
    /// - Parameters:
    ///   - spawnID: The UUID of the spawned power-up.
    ///   - playerID: The player who collected it.
    /// - Returns: The type of the collected power-up, or nil if not found/already collected.
    @discardableResult
    func collectPowerUp(spawnID: UUID, playerID: String) -> PowerUpType? {
        guard let index = spawnedPowerUps.firstIndex(where: { $0.id == spawnID }) else {
            AppLogger.gameplay.error("Power-up not found: \(spawnID)")
            return nil
        }
        
        guard !spawnedPowerUps[index].isCollected else {
            AppLogger.gameplay.info("Power-up already collected: \(spawnID)")
            return nil
        }
        
        let type = spawnedPowerUps[index].type
        spawnedPowerUps[index].isCollected = true
        spawnedPowerUps[index].collectedByPlayerID = playerID
        occupiedSlots.remove(spawnedPowerUps[index].spawnSlot)
        
        AppLogger.gameplay.info("Power-up collected: \(type.rawValue) by '\(playerID)'")
        
        return type
    }
    
    // MARK: - Private
    
    /// Schedules the next spawn after a random delay.
    private func scheduleNextSpawn() {
        let delay = TimeInterval.random(
            in: GameConstants.powerUpSpawnMinInterval...GameConstants.powerUpSpawnMaxInterval
        )
        
        spawnTimer = Just(())
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performSpawn()
            }
    }
    
    /// Attempts to spawn a random power-up, then schedules the next one.
    private func performSpawn() {
        if canSpawn {
            let type = PowerUpType.allCases.randomElement()!
            spawnPowerUp(ofType: type)
        }
        
        // Schedule next spawn regardless (will skip if at capacity)
        if isSpawning {
            scheduleNextSpawn()
        }
    }
    
    /// Creates a new spawned power-up at an available slot.
    private func spawnPowerUp(ofType type: PowerUpType) {
        guard let slot = findAvailableSlot() else {
            AppLogger.gameplay.debug("No available spawn slots")
            return
        }
        
        let powerUp = SpawnedPowerUp(type: type, spawnSlot: slot)
        spawnedPowerUps.append(powerUp)
        occupiedSlots.insert(slot)
        
        AppLogger.gameplay.info("Power-up spawned: \(type.rawValue) at slot \(slot)")
    }
    
    /// Finds a random unoccupied spawn slot.
    private func findAvailableSlot() -> Int? {
        let allSlots = Set(0..<GameConstants.powerUpSpawnSlots)
        let available = allSlots.subtracting(occupiedSlots)
        return available.randomElement()
    }
}
