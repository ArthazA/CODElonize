//
//  SpawnManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine
import os

/// Manages the random spawning, relocation, and probability-based claiming of power-ups
/// and Ember Moths during a match.
///
/// `SpawnManager` runs a recurring timer that spawns power-ups at random intervals
/// (15–45 seconds) at predefined spawn slot positions around the island.
/// It enforces a maximum of `GameConstants.maxActivePowerUps` uncollected power-ups
/// on the island at any time.
class SpawnManager: ObservableObject {
    
    /// All spawned power-ups (both collected and uncollected).
    @Published var spawnedPowerUps: [SpawnedPowerUp] = []
    
    /// All spawned Ember Moths (both collected and uncollected).
    @Published var spawnedEmberMoths: [SpawnedEmberMoth] = []
    
    /// Whether spawning is currently active.
    private(set) var isSpawning: Bool = false
    
    /// Timer for the next spawn.
    private var spawnTimer: AnyCancellable?
    
    /// Timer for power-up relocation (every 2 seconds).
    private var relocationTimer: AnyCancellable?
    
    /// Tracks which spawn slots are currently occupied by uncollected power-ups/moths.
    private var occupiedSlots: Set<Int> = []
    
    /// Per-player claim chance tracking.
    /// Key: player UUID, Value: current claim chance (starts at 10%).
    private var claimChances: [UUID: Double] = [:]
    
    // MARK: - Computed Properties
    
    /// Power-ups that are currently on the island (uncollected).
    var activePowerUps: [SpawnedPowerUp] {
        spawnedPowerUps.filter { !$0.isCollected }
    }
    
    /// Ember Moths that are currently on the island (uncollected).
    var activeEmberMoths: [SpawnedEmberMoth] {
        spawnedEmberMoths.filter { !$0.isCollected }
    }
    
    /// Whether the island can accept more power-up spawns.
    var canSpawn: Bool {
        activePowerUps.count < GameConstants.maxActivePowerUps
    }
    
    // MARK: - Spawn Control
    
    /// Starts the random spawn timer and relocation timer.
    func startSpawning() {
        guard !isSpawning else { return }
        isSpawning = true
        scheduleNextSpawn()
        startRelocationTimer()
        
        AppLogger.gameplay.info("Power-up spawning started")
    }
    
    /// Stops the spawn timer, relocation timer, and clears all spawns.
    func stopSpawning() {
        spawnTimer?.cancel()
        spawnTimer = nil
        relocationTimer?.cancel()
        relocationTimer = nil
        isSpawning = false
        
        AppLogger.gameplay.info("Power-up spawning stopped")
    }
    
    /// Resets all spawns (used when match ends or resets).
    func reset() {
        stopSpawning()
        spawnedPowerUps.removeAll()
        spawnedEmberMoths.removeAll()
        occupiedSlots.removeAll()
        claimChances.removeAll()
    }
    
    // MARK: - Forced Spawns
    
    /// Forces an Earthquake power-up to spawn immediately.
    /// Called when all areas are conquered (EC-026).
    func spawnEarthquake() {
        spawnPowerUp(ofType: .earthquake)
        AppLogger.gameplay.info("Forced Earthquake spawn (all areas conquered)")
    }
    
    /// Spawns an Ember Moth at a random available slot.
    /// Called during the Armageddon Phase.
    func spawnEmberMoth() {
        guard let slot = findAvailableSlot() else {
            AppLogger.gameplay.debug("No available spawn slots for Ember Moth")
            return
        }
        
        let moth = SpawnedEmberMoth(spawnSlot: slot)
        spawnedEmberMoths.append(moth)
        occupiedSlots.insert(slot)
        
        AppLogger.gameplay.info("Ember Moth spawned at slot \(slot)")
    }
    
    // MARK: - Probability-Based Claiming
    
    /// Attempts to claim a power-up using the probability-based mechanic.
    ///
    /// - Initial success chance: 10% (`GameConstants.initialClaimChance`)
    /// - On failure: chance increases by 7.5% (`GameConstants.claimChanceIncrease`)
    /// - On success: chance resets to initial value
    /// - On failure: power-up instantly relocates to a new slot
    ///
    /// - Parameters:
    ///   - spawnID: The UUID of the spawned power-up.
    ///   - playerID: The player attempting the claim.
    /// - Returns: The type of the claimed power-up on success, or nil on failure.
    @discardableResult
    func attemptClaim(spawnID: UUID, playerID: UUID) -> PowerUpType? {
        guard let index = spawnedPowerUps.firstIndex(where: { $0.id == spawnID }) else {
            AppLogger.gameplay.error("Power-up not found: \(spawnID)")
            return nil
        }
        
        guard !spawnedPowerUps[index].isCollected else {
            AppLogger.gameplay.info("Power-up already collected: \(spawnID)")
            return nil
        }
        
        // Get or initialize the player's current claim chance
        let currentChance = claimChances[playerID] ?? GameConstants.initialClaimChance
        
        // Roll the dice
        let roll = Double.random(in: 0.0..<1.0)
        let success = roll < currentChance
        
        if success {
            // Successful claim
            let type = spawnedPowerUps[index].type
            spawnedPowerUps[index].isCollected = true
            spawnedPowerUps[index].collectedByPlayerID = playerID.uuidString
            occupiedSlots.remove(spawnedPowerUps[index].spawnSlot)
            
            // Reset claim chance
            claimChances[playerID] = GameConstants.initialClaimChance
            
            AppLogger.gameplay.info(
                "Power-up claimed: \(type.rawValue) by '\(playerID)' (chance was \(String(format: "%.1f%%", currentChance * 100)))"
            )
            
            return type
        } else {
            // Failed claim — increase chance and relocate
            claimChances[playerID] = currentChance + GameConstants.claimChanceIncrease
            
            // Relocate the power-up
            relocatePowerUp(at: index)
            
            AppLogger.gameplay.info(
                "Claim failed for '\(playerID)' (chance was \(String(format: "%.1f%%", currentChance * 100)), next: \(String(format: "%.1f%%", (self.claimChances[playerID] ?? 0) * 100)))"
            )
            
            return nil
        }
    }
    
    /// Attempts to claim an Ember Moth using the same probability mechanic.
    ///
    /// - Parameters:
    ///   - mothID: The UUID of the spawned Ember Moth.
    ///   - playerID: The player attempting the claim.
    /// - Returns: `true` if the claim was successful.
    func attemptEmberMothClaim(mothID: UUID, playerID: UUID) -> Bool {
        guard let index = spawnedEmberMoths.firstIndex(where: { $0.id == mothID }) else {
            AppLogger.gameplay.error("Ember Moth not found: \(mothID)")
            return false
        }
        
        guard !spawnedEmberMoths[index].isCollected else {
            AppLogger.gameplay.info("Ember Moth already collected: \(mothID)")
            return false
        }
        
        let currentChance = claimChances[playerID] ?? GameConstants.initialClaimChance
        let roll = Double.random(in: 0.0..<1.0)
        let success = roll < currentChance
        
        if success {
            spawnedEmberMoths[index].isCollected = true
            spawnedEmberMoths[index].collectedByPlayerID = playerID.uuidString
            occupiedSlots.remove(spawnedEmberMoths[index].spawnSlot)
            
            claimChances[playerID] = GameConstants.initialClaimChance
            
            AppLogger.gameplay.info("Ember Moth claimed by '\(playerID)'")
            return true
        } else {
            claimChances[playerID] = currentChance + GameConstants.claimChanceIncrease
            
            // Relocate the moth
            relocateEmberMoth(at: index)
            
            AppLogger.gameplay.info("Ember Moth claim failed for '\(playerID)'")
            return false
        }
    }
    
    // MARK: - Legacy Collection (kept for compatibility)
    
    /// Marks a power-up as collected and frees its spawn slot.
    /// This is the legacy instant-collection method, preserved for host-side forced collection.
    ///
    /// - Parameters:
    ///   - spawnID: The UUID of the spawned power-up.
    ///   - playerID: The player who collected it.
    /// - Returns: The type of the collected power-up, or nil if not found/already collected.
    @discardableResult
    func collectPowerUp(spawnID: UUID, playerID: UUID) -> PowerUpType? {
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
        spawnedPowerUps[index].collectedByPlayerID = playerID.uuidString
        occupiedSlots.remove(spawnedPowerUps[index].spawnSlot)
        
        AppLogger.gameplay.info("Power-up collected (direct): \(type.rawValue) by '\(playerID)'")
        
        return type
    }
    
    // MARK: - Relocation
    
    /// Relocates a specific power-up to a new random slot.
    private func relocatePowerUp(at index: Int) {
        let oldSlot = spawnedPowerUps[index].spawnSlot
        occupiedSlots.remove(oldSlot)
        
        if let newSlot = findAvailableSlot() {
            spawnedPowerUps[index].spawnSlot = newSlot
            occupiedSlots.insert(newSlot)
            
            AppLogger.gameplay.debug("Power-up relocated: slot \(oldSlot) → \(newSlot)")
        } else {
            // No available slot — keep in current position
            occupiedSlots.insert(oldSlot)
            AppLogger.gameplay.debug("Power-up relocation failed: no available slots")
        }
    }
    
    /// Relocates a specific Ember Moth to a new random slot.
    private func relocateEmberMoth(at index: Int) {
        let oldSlot = spawnedEmberMoths[index].spawnSlot
        occupiedSlots.remove(oldSlot)
        
        if let newSlot = findAvailableSlot() {
            spawnedEmberMoths[index].spawnSlot = newSlot
            occupiedSlots.insert(newSlot)
        } else {
            occupiedSlots.insert(oldSlot)
        }
    }
    
    /// Relocates all active (uncollected) power-ups to new random positions.
    /// Called every `GameConstants.powerUpMoveInterval` seconds.
    private func relocateAllActive() {
        for i in spawnedPowerUps.indices where !spawnedPowerUps[i].isCollected {
            relocatePowerUp(at: i)
        }
        for i in spawnedEmberMoths.indices where !spawnedEmberMoths[i].isCollected {
            relocateEmberMoth(at: i)
        }
    }
    
    // MARK: - Private
    
    /// Starts the periodic relocation timer.
    private func startRelocationTimer() {
        relocationTimer = Timer.publish(
            every: GameConstants.powerUpMoveInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.relocateAllActive()
        }
    }
    
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
