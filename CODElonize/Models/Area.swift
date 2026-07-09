
import Foundation

struct Area: Identifiable, Equatable {

    let index: Int

    var id: Int { index }

    let topic: String

    var ownerID: String? = nil

    var bestTime: TimeInterval? = nil

    var isLocked: Bool = false

    var lockRemainingTime: TimeInterval = 0

    var isArmageddonLocked: Bool = false

    var questionSeed: UInt64

    var attemptRecords: [String: TimeInterval] = [:]

    var isConquered: Bool {
        ownerID != nil
    }

    var isAvailable: Bool {
        !isLocked && !isArmageddonLocked
    }

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
