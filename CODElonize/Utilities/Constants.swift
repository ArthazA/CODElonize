
import Foundation
import simd

enum GameConstants {

    static let islandModelName = "Islands"

    static let defaultIslandScale: Float = 2

    static let minIslandScale: Float = 0.005

    static let maxIslandScale: Float = 0.05

    static let maxPlayers = 5

    static let areaCount = 7

    static let armageddonAreaIndex = 6

    static let mcqPerAttempt = 3

    static let arrangementPerAttempt = 2

    static let questionsPerAttempt = 5

    static let areaTopics = [
        "SwiftUI",
        "Algorithms",
        "Data Structures",
        "Networking",
        "Databases",
        "OOP",
        "Frameworks"
    ]

    static let pinpointPositions: [SIMD3<Float>] = [
        SIMD3<Float>( 0.00,  0.03, -0.30),  
        SIMD3<Float>( 0.14,  0.04, -0.05),  
        SIMD3<Float>(-0.33,  0.11, -0.10),  
        SIMD3<Float>( 0.31,  0.21,  0.14),  
        SIMD3<Float>(-0.10,  0.02,  0.09),  
        SIMD3<Float>( 0.03,  0.05,  0.24),  
        SIMD3<Float>( 0.20,  0.08,  0.30),  
    ]

    static let pinpointCollisionRadius: Float = 0.015

    static let pinpointVisualRadius: Float = 0.008

    static let matchDuration: TimeInterval = 300

    static let wrongAnswerPenalty: TimeInterval = 3

    static let pocketWatchReduction: Float = 0.20

    static let tsunamiLockDuration: TimeInterval = 30

    static let quizTimerUpdateInterval: TimeInterval = 0.1

    static let topicFileMapping: [String: String] = [
        "SwiftUI": "swiftui",
        "Algorithms": "algorithms",
        "Data Structures": "datastructures",
        "Networking": "networking",
        "Databases": "databases",
        "OOP": "oop",
        "Frameworks": "frameworks"
    ]

    static let powerUpSpawnMinInterval: TimeInterval = 15

    static let powerUpSpawnMaxInterval: TimeInterval = 45

    static let maxActivePowerUps: Int = 3

    static let powerUpSpawnSlots: Int = 5

    static let maxInventorySize: Int = 1

    static let initialClaimChance: Double = 0.10

    static let claimChanceIncrease: Double = 0.075

    static let powerUpMoveInterval: TimeInterval = 2

    static let armageddonRemainingTime: TimeInterval = 60

    static let emberMothPoints: Double = 0.5

    static let lobbyCodeLength = 4
}
