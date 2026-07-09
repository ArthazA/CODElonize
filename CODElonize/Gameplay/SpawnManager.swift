
import Foundation
import Combine
import os

class SpawnManager: ObservableObject {

    @Published var spawnedPowerUps: [SpawnedPowerUp] = []

    @Published var spawnedEmberMoths: [SpawnedEmberMoth] = []

    private(set) var isSpawning: Bool = false

    private var spawnTimer: AnyCancellable?

    private var relocationTimer: AnyCancellable?

    private var occupiedSlots: Set<Int> = []

    private var claimChances: [UUID: Double] = [:]

    var activePowerUps: [SpawnedPowerUp] {
        spawnedPowerUps.filter { !$0.isCollected }
    }

    var activeEmberMoths: [SpawnedEmberMoth] {
        spawnedEmberMoths.filter { !$0.isCollected }
    }

    var canSpawn: Bool {
        activePowerUps.count < GameConstants.maxActivePowerUps
    }

    func startSpawning() {
        guard !isSpawning else { return }
        isSpawning = true
        scheduleNextSpawn()
        startRelocationTimer()

        AppLogger.gameplay.info("Power-up spawning started")
    }

    func stopSpawning() {
        spawnTimer?.cancel()
        spawnTimer = nil
        relocationTimer?.cancel()
        relocationTimer = nil
        isSpawning = false

        AppLogger.gameplay.info("Power-up spawning stopped")
    }

    func reset() {
        stopSpawning()
        spawnedPowerUps.removeAll()
        spawnedEmberMoths.removeAll()
        occupiedSlots.removeAll()
        claimChances.removeAll()
    }

    func spawnEarthquake() {
        spawnPowerUp(ofType: .earthquake)
        AppLogger.gameplay.info("Forced Earthquake spawn (all areas conquered)")
    }

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

        let currentChance = claimChances[playerID] ?? GameConstants.initialClaimChance

        let roll = Double.random(in: 0.0..<1.0)
        let success = roll < currentChance

        if success {

            let type = spawnedPowerUps[index].type
            spawnedPowerUps[index].isCollected = true
            spawnedPowerUps[index].collectedByPlayerID = playerID.uuidString
            occupiedSlots.remove(spawnedPowerUps[index].spawnSlot)

            claimChances[playerID] = GameConstants.initialClaimChance

            AppLogger.gameplay.info(
                "Power-up claimed: \(type.rawValue) by '\(playerID)' (chance was \(String(format: "%.1f%%", currentChance * 100)))"
            )

            return type
        } else {

            claimChances[playerID] = currentChance + GameConstants.claimChanceIncrease

            relocatePowerUp(at: index)

            AppLogger.gameplay.info(
                "Claim failed for '\(playerID)' (chance was \(String(format: "%.1f%%", currentChance * 100)), next: \(String(format: "%.1f%%", (self.claimChances[playerID] ?? 0) * 100)))"
            )

            return nil
        }
    }

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

            relocateEmberMoth(at: index)

            AppLogger.gameplay.info("Ember Moth claim failed for '\(playerID)'")
            return false
        }
    }

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

    private func relocatePowerUp(at index: Int) {
        let oldSlot = spawnedPowerUps[index].spawnSlot
        occupiedSlots.remove(oldSlot)

        if let newSlot = findAvailableSlot() {
            spawnedPowerUps[index].spawnSlot = newSlot
            occupiedSlots.insert(newSlot)

            AppLogger.gameplay.debug("Power-up relocated: slot \(oldSlot) → \(newSlot)")
        } else {

            occupiedSlots.insert(oldSlot)
            AppLogger.gameplay.debug("Power-up relocation failed: no available slots")
        }
    }

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

    private func relocateAllActive() {
        for i in spawnedPowerUps.indices where !spawnedPowerUps[i].isCollected {
            relocatePowerUp(at: i)
        }
        for i in spawnedEmberMoths.indices where !spawnedEmberMoths[i].isCollected {
            relocateEmberMoth(at: i)
        }
    }

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

    private func performSpawn() {
        if canSpawn {
            let type = PowerUpType.allCases.randomElement()!
            spawnPowerUp(ofType: type)
        }

        if isSpawning {
            scheduleNextSpawn()
        }
    }

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

    private func findAvailableSlot() -> Int? {
        let allSlots = Set(0..<GameConstants.powerUpSpawnSlots)
        let available = allSlots.subtracting(occupiedSlots)
        return available.randomElement()
    }
}
