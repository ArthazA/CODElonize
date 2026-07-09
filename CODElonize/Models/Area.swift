//
//  Area.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

/// Represents one of the seven conquerable areas on the island.
///
/// Each area has a learning topic, tracks ownership via best completion time,
/// and can be temporarily locked (e.g., by Tsunami power-up).
/// The 7th area (index 6) starts Armageddon-locked and is only unlocked
/// during the Armageddon Phase (final 60 seconds).
struct Area: Identifiable, Equatable {
    
    /// The area index (0–6), also serves as the unique identifier.
    let index: Int
    
    /// Convenience identifier for `Identifiable` conformance.
    var id: Int { index }
    
    /// The learning topic for this area (e.g. "Algorithms", "SwiftUI").
    let topic: String
    
    /// The player ID of the current owner, or nil if unconquered.
    var ownerID: String? = nil
    
    /// The fastest completion time recorded for this area.
    var bestTime: TimeInterval? = nil
    
    /// Whether the area is temporarily locked (e.g., by Tsunami).
    var isLocked: Bool = false
    
    /// Remaining lock time in seconds. Counts down to zero.
    var lockRemainingTime: TimeInterval = 0
    
    /// Whether this area is Armageddon-locked (only the 7th area).
    /// This lock is permanent until the Armageddon Phase unlocks it.
    var isArmageddonLocked: Bool = false
    
    /// The shared seed for deterministic question selection.
    /// Generated when the match starts and regenerated on Earthquake reset.
    var questionSeed: UInt64
    
    /// All recorded attempts for this area.
    /// Key: player ID, Value: completion time in seconds.
    var attemptRecords: [String: TimeInterval] = [:]
    
    // MARK: - Computed Properties
    
    /// Whether this area has been conquered by any player.
    var isConquered: Bool {
        ownerID != nil
    }
    
    /// Whether this area is available for a new attempt
    /// (not locked by Tsunami and not Armageddon-locked).
    var isAvailable: Bool {
        !isLocked && !isArmageddonLocked
    }
    
    // MARK: - Factory
    
    /// Creates the initial set of 7 areas with topics from `GameConstants`.
    /// The last area (index 6) is Armageddon-locked.
    static func createAllAreas() -> [Area] {
        (0..<GameConstants.areaCount).map { index in
            Area(
                index: index,
                topic: GameConstants.areaTopics[index],
                isArmageddonLocked: index == GameConstants.armageddonAreaIndex,
                questionSeed: Randomizer.generateSeed()
            )
        }
    }
}
