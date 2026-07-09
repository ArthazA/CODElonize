
import Foundation

enum PowerUpType: String, CaseIterable, Codable, Equatable {
    case earthquake
    case tsunami
    case pocketWatch

    var displayName: String {
        switch self {
        case .earthquake: return "Earthquake"
        case .tsunami: return "Tsunami"
        case .pocketWatch: return "Pocket Watch"
        }
    }

    var iconName: String {
        switch self {
        case .earthquake: return "bolt.trianglebadge.exclamationmark.fill"
        case .tsunami: return "water.waves"
        case .pocketWatch: return "stopwatch.fill"
        }
    }

    var colorName: String {
        switch self {
        case .earthquake: return "brown"
        case .tsunami: return "blue"
        case .pocketWatch: return "purple"
        }
    }
}

struct SpawnedPowerUp: Identifiable, Equatable {

    let id: UUID

    let type: PowerUpType

    var spawnSlot: Int

    var isCollected: Bool = false

    var collectedByPlayerID: String? = nil

    let spawnTime: Date

    init(type: PowerUpType, spawnSlot: Int) {
        self.id = UUID()
        self.type = type
        self.spawnSlot = spawnSlot
        self.spawnTime = Date()
    }
}

struct SpawnedEmberMoth: Identifiable, Equatable {

    let id: UUID

    var spawnSlot: Int

    var isCollected: Bool = false

    var collectedByPlayerID: String? = nil

    let spawnTime: Date

    static let iconName = "flame.fill"

    static let displayName = "Ember Moth"

    init(spawnSlot: Int) {
        self.id = UUID()
        self.spawnSlot = spawnSlot
        self.spawnTime = Date()
    }
}
