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
    
    /// Default scale applied to the island model when first placed.
    /// The host can adjust this from the Lobby before the match starts.
    static let defaultIslandScale: Float = 2
    
    /// Minimum scale the host can set for the island.
    static let minIslandScale: Float = 0.005
    
    /// Maximum scale the host can set for the island.
    static let maxIslandScale: Float = 0.05
    
    // MARK: - Players
    
    /// Maximum number of players per lobby.
    static let maxPlayers = 5
    
    // MARK: - Areas
    
    /// Number of conquerable areas on the island (6 normal + 1 Armageddon-locked).
    static let areaCount = 7
    
    /// The index of the Armageddon-locked area (0-indexed).
    static let armageddonAreaIndex = 6
    
    /// Number of MCQ questions per area attempt.
    static let mcqPerAttempt = 3
    
    /// Number of Code Arrangement questions per area attempt.
    static let arrangementPerAttempt = 2
    
    /// Total number of questions per area attempt (3 MCQ + 2 Code Arrangement).
    static let questionsPerAttempt = 5
    
    /// The learning topics mapped to each area index.
    static let areaTopics = [
        "SwiftUI",
        "Algorithms",
        "Data Structures",
        "Networking",
        "Databases",
        "OOP",
        "Frameworks"
    ]
    
    /// Pinpoint positions relative to the island entity's local origin.
    /// These are placeholder coordinates — adjust after testing with the actual Islands.usdz model.
    static let pinpointPositions: [SIMD3<Float>] = [
        SIMD3<Float>( 0.00,  0.03, -0.30),  // Area 0 — SwiftUI (Mountain)
        SIMD3<Float>( 0.14,  0.04, -0.05),  // Area 1 — Algorithms (Forest East)
        SIMD3<Float>(-0.33,  0.11, -0.10),  // Area 2 — Data Structures (Forest West)
        SIMD3<Float>( 0.31,  0.21,  0.14),  // Area 3 — Networking (River)
        SIMD3<Float>(-0.10,  0.02,  0.09),  // Area 4 — Databases (Village)
        SIMD3<Float>( 0.03,  0.05,  0.24),  // Area 5 — OOP (Center)
        SIMD3<Float>( 0.20,  0.08,  0.30),  // Area 6 — Frameworks (Armageddon-locked)
    ]
    
    /// Collision radius for each pinpoint (used for tap detection).
    static let pinpointCollisionRadius: Float = 0.015
    
    /// Visual radius of the pinpoint sphere marker.
    static let pinpointVisualRadius: Float = 0.008
    
    // MARK: - Match
    
    /// Default match duration in seconds (5 minutes).
    static let matchDuration: TimeInterval = 300
    
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
    
    // MARK: - Claim Mechanic
    
    /// Initial chance of successfully claiming a power-up on tap (10%).
    static let initialClaimChance: Double = 0.10
    
    /// Increase in claim chance per failed attempt (+7.5%).
    static let claimChanceIncrease: Double = 0.075
    
    /// Interval in seconds between power-up relocations.
    static let powerUpMoveInterval: TimeInterval = 2
    
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
