
import Foundation

enum MessageType: String, Codable {
    case join
    case lobbyUpdate
    case ready
    case startGame
    case areaCaptured
    case powerUp
    case timer
    case score
    case finish
}
