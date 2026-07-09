import RealityKit
import UIKit
import os

/// Manages 3D AR entities for power-ups and Ember Moths spawned on the island.
///
/// Mirrors `PinpointSystem`'s create/hit-test pattern. Visuals are placeholder
/// colored "orbs" — swap the TODO(art) line below for `Entity.load(named:)`
/// once real assets exist, one per `PowerUpType` plus one for Ember Moth.
class PowerUpEntitySystem {

    private var powerUpEntities: [UUID: Entity] = [:]
    private var emberMothEntities: [UUID: Entity] = [:]

    private func color(for type: PowerUpType) -> UIColor {
        switch type {
        case .earthquake: return .systemBrown
        case .tsunami: return .systemBlue
        case .pocketWatch: return .systemPurple
        }
    }

    private let emberMothColor: UIColor = .systemOrange

    // MARK: - Sync

    /// Reconciles AR entities against `SpawnManager`'s current state: adds
    /// entities for new spawns, removes them on collection, repositions them
    /// on relocation. Call this whenever `SpawnManager` publishes a change.
    func sync(powerUps: [SpawnedPowerUp], emberMoths: [SpawnedEmberMoth], islandAnchor: AnchorEntity) {
        syncEntities(
            active: powerUps.filter { !$0.isCollected },
            idFor: { $0.id },
            slotFor: { $0.spawnSlot },
            existing: &powerUpEntities,
            islandAnchor: islandAnchor,
            makeEntity: { self.makeOrbEntity(id: $0.id, kind: "powerup", color: self.color(for: $0.type)) }
        )

        syncEntities(
            active: emberMoths.filter { !$0.isCollected },
            idFor: { $0.id },
            slotFor: { $0.spawnSlot },
            existing: &emberMothEntities,
            islandAnchor: islandAnchor,
            makeEntity: { self.makeOrbEntity(id: $0.id, kind: "embermoth", color: self.emberMothColor) }
        )
    }

    private func syncEntities<T>(
        active: [T],
        idFor: (T) -> UUID,
        slotFor: (T) -> Int,
        existing: inout [UUID: Entity],
        islandAnchor: AnchorEntity,
        makeEntity: (T) -> Entity
    ) {
        let activeIDs = Set(active.map(idFor))

        for (id, entity) in existing where !activeIDs.contains(id) {
            entity.removeFromParent()
            existing.removeValue(forKey: id)
        }

        for spawn in active {
            let id = idFor(spawn)
            let slot = slotFor(spawn)
            guard slot < GameConstants.powerUpSpawnPositions.count else { continue }
            let position = GameConstants.powerUpSpawnPositions[slot]

            if let entity = existing[id] {
                if entity.position != position {
                    entity.position = position
                }
            } else {
                let entity = makeEntity(spawn)
                entity.position = position
                islandAnchor.addChild(entity)
                existing[id] = entity
            }
        }
    }

    // MARK: - Entity Creation

    /// TODO(art): replace this sphere with a real 3D asset — call
    /// `Entity.load(named: "...")` here per power-up type / Ember Moth once
    /// models exist, same pattern as `IslandPlacement.loadIslandModel()`.
    private func makeOrbEntity(id: UUID, kind: String, color: UIColor) -> Entity {
        let root = Entity()
        root.name = "\(kind)_\(id.uuidString)"

        let orb = ModelEntity.makeSphere(
            radius: 0.012,
            color: color,
            collisionRadius: 0.02
        )
        root.addChild(orb)

        return root
    }

    // MARK: - Removal

    func removeAll() {
        powerUpEntities.values.forEach { $0.removeFromParent() }
        emberMothEntities.values.forEach { $0.removeFromParent() }
        powerUpEntities.removeAll()
        emberMothEntities.removeAll()
    }
}

extension Entity {
    /// Walks up the hierarchy to find a power-up/Ember Moth spawn ID, mirroring
    /// `findPinpointAreaIndex()`. Returns the spawn UUID and its kind
    /// ("powerup" or "embermoth").
    func findPowerUpSpawnID() -> (id: UUID, kind: String)? {
        var current: Entity? = self
        while let entity = current {
            if entity.name.hasPrefix("powerup_") || entity.name.hasPrefix("embermoth_") {
                let parts = entity.name.split(separator: "_", maxSplits: 1)
                if parts.count == 2, let id = UUID(uuidString: String(parts[1])) {
                    return (id, String(parts[0]))
                }
            }
            current = entity.parent
        }
        return nil
    }
}
