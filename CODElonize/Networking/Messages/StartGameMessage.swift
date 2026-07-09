import Foundation

/// Sent by the host when the match begins.
///
/// EXTENDED (README §6.3): originally only carried `startTime`. Now also
/// carries the 7 host-generated `questionSeeds` (one per area, so every
/// device's `Randomizer` produces identical question sets — a fairness
/// requirement already designed into `Randomizer`/`QuizManager` but not
/// previously wired to the network) and the final `players` list the match
/// should start with.
struct StartGameMessage: Codable {
    /// The shared epoch all devices use to compute `remainingTime` locally
    /// and in sync (see `TimerSystem.start(from:duration:)`).
    let startTime: Date
    
    /// One deterministic seed per area (`GameConstants.areaCount` values),
    /// generated once by the host so all devices produce identical
    /// randomized question sets per area.
    let questionSeeds: [UInt64]
    
    /// The final player roster the match starts with.
    let players: [Player]
}
