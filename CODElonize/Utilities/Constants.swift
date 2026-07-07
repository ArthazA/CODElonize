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
    
    /// Number of conquerable areas on the island.
    static let areaCount = 6
    
    /// Number of questions per area attempt.
    static let questionsPerAttempt = 3
    
    /// The learning topics mapped to each area index.
    static let areaTopics = [
        "Algorithms",
        "AI",
        "Cybersecurity",
        "OOP",
        "Computer Networks",
        "Database"
    ]
    
    /// Pinpoint positions relative to the island entity's local origin.
    /// These are placeholder coordinates — adjust after testing with the actual Islands.usdz model.
    static let pinpointPositions: [SIMD3<Float>] = [
        SIMD3<Float>( 0.00,  0.03, -0.30),  // Area 0 (RED) — Algorithms (Mountain)
        SIMD3<Float>( 0.14,  0.04, -0.05),  // Area 1 (PINK) — AI (Forest East)
        SIMD3<Float>(-0.33,  0.11, -0.10),  // Area 2 (GREEN) — Cybersecurity (Forest West)
        SIMD3<Float>( 0.31,  0.21,  0.14),  // Area 3 (BLUE) — OOP (River)
        SIMD3<Float>(-0.10,  0.02,  0.09),  // Area 4 (ORANGE) — Computer Networks (Village)
        SIMD3<Float>( 0.03,  0.05,  0.24),  // Area 5 (YELLOW) — Database (Center)
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
    
    /// Pocket Watch time reduction factor (10%).
    static let pocketWatchReduction: Float = 0.10
    
    /// Duration in seconds that a Tsunami power-up locks an area.
    static let tsunamiLockDuration: TimeInterval = 30
    
    // MARK: - Quiz
    
    /// How frequently the quiz elapsed timer updates (in seconds).
    static let quizTimerUpdateInterval: TimeInterval = 0.1
    
    /// Maps the display topic names (from `areaTopics`) to their JSON filenames (without extension).
    /// The JSON files live in the app bundle under `Questions/`.
    static let topicFileMapping: [String: String] = [
        "Algorithms": "algorithms",
        "AI": "ai",
        "Cybersecurity": "cybersecurity",
        "OOP": "oop",
        "Computer Networks": "computernetworks",
        "Database": "database"
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
    
    /// Maximum number of power-ups a player can hold in inventory.
    static let maxInventorySize: Int = 3
    
    // MARK: - Lobby
    
    /// Number of digits in a lobby code.
    static let lobbyCodeLength = 4
}
