
import Foundation

struct LobbyUpdateMessage: Codable {
    let roomCode: String
    let hostID: UUID
    let players: [Player]
    let maxPlayers: Int
}
