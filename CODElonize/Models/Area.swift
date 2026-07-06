//
//  Area.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

/// Represents one of the six conquerable areas on the island.
///
/// Each area has a learning topic, tracks ownership via best completion time,
/// and can be temporarily locked (e.g., by Tsunami power-up).
struct Area: Identifiable, Equatable {
    
    /// The area index (0–5), also serves as the unique identifier.
    let index: Int
    
    /// Convenience identifier for `Identifiable` conformance.
    var id: Int { index }
    
    /// The learning topic for this area (e.g. "Algorithms", "AI").
    let topic: String
    
    /// The player ID of the current owner, or nil if unconquered.
    var ownerID: String? = nil
    
    /// The fastest completion time recorded for this area.
    var bestTime: TimeInterval? = nil
    
    /// Whether the area is temporarily locked (e.g., by Tsunami).
    var isLocked: Bool = false
    
    /// Remaining lock time in seconds. Counts down to zero.
    var lockRemainingTime: TimeInterval = 0
    
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
    /// (not locked and match is active).
    var isAvailable: Bool {
        !isLocked
    }
    
    // MARK: - Factory
    
    /// Creates the initial set of 6 areas with topics from `GameConstants`.
    static func createAllAreas() -> [Area] {
        (0..<GameConstants.areaCount).map { index in
            Area(
                index: index,
                topic: GameConstants.areaTopics[index],
                questionSeed: Randomizer.generateSeed()
            )
        }
    }
}
