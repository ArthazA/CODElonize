//
//  PowerUp.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

/// The three types of power-ups available in CODElonize.
///
/// Each power-up has a distinct strategic effect on area conquest:
/// - **Earthquake**: Resets an area completely (owner, times, questions)
/// - **Tsunami**: Temporarily locks an area and kicks active players
/// - **Pocket Watch**: Reduces the activating player's time by 10%
enum PowerUpType: String, CaseIterable, Codable, Equatable {
    case earthquake
    case tsunami
    case pocketWatch
    
    /// Display name for the UI.
    var displayName: String {
        switch self {
        case .earthquake: return "Earthquake"
        case .tsunami: return "Tsunami"
        case .pocketWatch: return "Pocket Watch"
        }
    }
    
    /// SF Symbol icon name for the HUD and spawn display.
    var iconName: String {
        switch self {
        case .earthquake: return "bolt.trianglebadge.exclamationmark.fill"
        case .tsunami: return "water.waves"
        case .pocketWatch: return "stopwatch.fill"
        }
    }
    
    /// Accent color for UI differentiation.
    var colorName: String {
        switch self {
        case .earthquake: return "brown"
        case .tsunami: return "blue"
        case .pocketWatch: return "purple"
        }
    }
}

/// A power-up instance that has been spawned on the island.
///
/// Spawned power-ups exist as collectible items until a player picks them up.
/// Once collected, they move into the player's inventory.
struct SpawnedPowerUp: Identifiable, Equatable {
    /// Unique identifier for this spawn instance.
    let id: UUID
    
    /// The type of power-up.
    let type: PowerUpType
    
    /// The spawn slot index (0–4) determining its position on the island.
    let spawnSlot: Int
    
    /// Whether this power-up has been collected by a player.
    var isCollected: Bool = false
    
    /// The ID of the player who collected this power-up (nil if uncollected).
    var collectedByPlayerID: String? = nil
    
    /// When this power-up was spawned (for display/cleanup purposes).
    let spawnTime: Date
    
    /// Creates a new spawned power-up.
    init(type: PowerUpType, spawnSlot: Int) {
        self.id = UUID()
        self.type = type
        self.spawnSlot = spawnSlot
        self.spawnTime = Date()
    }
}
