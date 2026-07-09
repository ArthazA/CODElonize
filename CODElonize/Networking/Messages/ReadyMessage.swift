
import Foundation

struct ReadyMessage: Codable {
    let playerID: UUID
    let isReady: Bool
}
