//
//  Constants.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import simd

/// Centralized game constants used across all modules.
enum GameConstants {
    
    // MARK: - Island
    
    /// The filename of the island 3D model (without extension).
    static let islandModelName = "Islands"
    
    /// Minimum scale the host can set for the island.
    static let minIslandScale: Float = 0.01
    
    /// Maximum scale the host can set for the island.
    static let maxIslandScale: Float = 0.05
    
    /// Default scale applied to the island model when first placed.
    /// The host can adjust this from the Lobby before the match starts.
    ///
    /// FIX (README §5.6/§9): this was previously `2`, far outside the
    /// documented `minIslandScale...maxIslandScale` range, which would have
    /// rendered the island absurdly (or invisibly) large relative to a real
    /// tabletop AR scene. Set to a sensible mid-range default instead.
    static let defaultIslandScale: Float = 0.03
    
    // MARK: - Players
    
    /// Maximum number of players per lobby.
    static let maxPlayers = 5
    
    // MARK: - Areas
    
    /// Number of conquerable areas on the island (6 normal + 1 Armageddon-locked).
    static let areaCount = 7
    
    /// The index of the Armageddon-locked area (0-indexed).
    static let armageddonAreaIndex = 6
    
    /// Number of MCQ questions per area attempt.
    static let mcqPerAttempt = 5
    
    /// Number of Code Arrangement questions per area attempt.
    static let arrangementPerAttempt = 0
    
    /// Total number of questions per area attempt (3 MCQ + 2 Code Arrangement).
    static let questionsPerAttempt = 5
    
    /// The learning topics mapped to each area index.
    /// Canonical list confirmed in README §3.8 — do not reorder without
    /// updating `topicFileMapping` and the `Questions/*.json` bundle below.
    static let areaTopics = [
        "SwiftUI",
        "Algorithms",
        "Data Structures",
        "Networking",
        "Databases",
        "OOP",
        "Frameworks"
    ]
    
    /// Collision radius for each pinpoint (used for tap detection).
    static let pinpointCollisionRadius: Float = 0.015 * 25
    
    /// Visual radius of the pinpoint sphere marker.
    static let pinpointVisualRadius: Float = 0.3
    
    // MARK: - Match
    
    /// Default match duration in seconds (5 minutes).
    static let matchDuration: TimeInterval = 180
    
    /// Time penalty in seconds when a wrong answer is given (UI freeze).
    static let wrongAnswerPenalty: TimeInterval = 3
    
    /// Pocket Watch time reduction factor (20%).
    static let pocketWatchReduction: Float = 0.20
    
    /// Duration in seconds that a Tsunami power-up locks an area.
    static let tsunamiLockDuration: TimeInterval = 30
    
    // MARK: - Quiz
    
    /// How frequently the quiz elapsed timer updates (in seconds).
    static let quizTimerUpdateInterval: TimeInterval = 0.1
    
    /// Maps the display topic names (from `areaTopics`) to their JSON filenames (without extension).
    /// The JSON files live in the app bundle under `Questions/`.
    static let topicFileMapping: [String: String] = [
        "SwiftUI": "swiftui",
        "Algorithms": "algorithms",
        "Data Structures": "datastructures",
        "Networking": "networking",
        "Databases": "databases",
        "OOP": "oop",
        "Frameworks": "frameworks"
    ]
    
    // MARK: - Power-ups
    
    /// Minimum delay (seconds) between power-up spawns.
    static let powerUpSpawnMinInterval: TimeInterval = 15
    
    /// Maximum delay (seconds) between power-up spawns.
    static let powerUpSpawnMaxInterval: TimeInterval = 45
    
    /// Maximum number of uncollected power-ups on the island at once.
    static let maxActivePowerUps: Int = 3
    
    /// Number of predefined spawn positions around the island.
    static let powerUpSpawnSlots: Int = 5
    
    /// Maximum number of power-ups a player can hold in inventory (ONE slot per spec).
    static let maxInventorySize: Int = 1
    
    /// 3D positions (relative to the island anchor) for each power-up spawn slot.
    ///
    /// ADDED (README §5.5): building power-ups as real AR entities requires a
    /// position table analogous to `pinpointPositions`. These are placeholder
    /// coordinates chosen to sit between/around the pinpoints — adjust once
    /// tested against the actual `Islands.usdz` model. Count must match
    /// `powerUpSpawnSlots`.
    static let powerUpSpawnPositions: [SIMD3<Float>] = [
        SIMD3<Float>( 0.10,  0.06, -0.18),  // Slot 0
        SIMD3<Float>(-0.20,  0.07,  0.00),  // Slot 1
        SIMD3<Float>( 0.22,  0.09,  0.02),  // Slot 2
        SIMD3<Float>(-0.05,  0.04,  0.18),  // Slot 3
        SIMD3<Float>( 0.00,  0.10,  0.00),  // Slot 4 (island center, elevated)
    ]
    
    // MARK: - Claim Mechanic
    
    /// Initial chance of successfully claiming a power-up on tap (10%).
    static let initialClaimChance: Double = 0.10
    
    /// Increase in claim chance per failed attempt (+7.5%).
    static let claimChanceIncrease: Double = 0.075
    
    /// How long (in seconds) an individual power-up/Ember Moth can sit
    /// uninteracted before it relocates on its own.
    ///
    /// ADDED (README §5.4): the design was clarified to be a *per-entity*
    /// timeout ("static until tapped, or until 2 seconds elapse without
    /// interaction") rather than a single global synchronized tick that moves
    /// every spawn at once. `SpawnManager` tracks each spawn's own
    /// `lastInteractionTime` and compares it against this value independently.
    static let powerUpIdleRelocateTimeout: TimeInterval = 2
    
    /// How frequently the idle-relocation watcher checks each entity's
    /// elapsed idle time. This is just a polling granularity, not a
    /// synchronized "move everyone now" tick — each entity only actually
    /// relocates once *it individually* has exceeded `powerUpIdleRelocateTimeout`.
    static let powerUpIdleCheckInterval: TimeInterval = 0.5
    
    // MARK: - Armageddon
    
    /// Remaining match time (in seconds) at which Armageddon Phase triggers.
    static let armageddonRemainingTime: TimeInterval = 60
    
    // MARK: - Ember Moth
    
    /// Points awarded for collecting an Ember Moth.
    static let emberMothPoints: Double = 0.5
    
    // MARK: - Lobby
    
    /// Number of digits in a lobby code.
    static let lobbyCodeLength = 4
}
