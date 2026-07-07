//
//  MatchManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine
import os

/// Central coordinator that ties together all gameplay systems.
///
/// `MatchManager` is the single `ObservableObject` injected into the SwiftUI environment.
/// It owns the `GameState`, `QuizManager`, and `TimerSystem`, and orchestrates the
/// full gameplay loop: pinpoint tap → quiz → time recording → conquest → leaderboard.
///
/// In the future, networking will call `MatchManager`'s public methods when receiving
/// host broadcasts, without requiring any structural changes.
class MatchManager: ObservableObject {
    
    // MARK: - Sub-Managers
    
    /// The authoritative game state.
    let gameState = GameState()
    
    /// The quiz system from Phase 5.
    let quizManager = QuizManager()
    
    /// The match countdown timer.
    let timerSystem = TimerSystem()
    
    // MARK: - Published UI State
    
    /// Whether the quiz overlay is currently showing.
    @Published var isQuizActive: Bool = false
    
    /// The area index currently being quizzed (nil if no quiz active).
    @Published var activeAreaIndex: Int? = nil
    
    /// Live sorted leaderboard for the HUD.
    @Published var leaderboard: [PlayerScore] = []
    
    /// The final match result (set when the match finishes).
    @Published var matchResult: MatchResult? = nil
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupTimerExpiry()
        setupGameStateObservation()
    }
    
    /// Wires the timer's expiry callback to end the match.
    private func setupTimerExpiry() {
        timerSystem.onExpired = { [weak self] in
            AppLogger.gameplay.info("Timer expired — ending match")
            self?.endMatch()
        }
    }
    
    /// Observes GameState changes to keep the leaderboard up to date.
    private func setupGameStateObservation() {
        // Refresh leaderboard whenever areas or players change
        gameState.$areas
            .combineLatest(gameState.$players)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.refreshLeaderboard()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Match Lifecycle
    
    /// Starts a new match with the given players.
    ///
    /// For single-player testing, pass a single player. For multiplayer,
    /// the networking layer will provide all connected players.
    ///
    /// - Parameters:
    ///   - players: The players participating in the match.
    ///   - localPlayerID: The ID of the player on this device.
    func startMatch(players: [Player], localPlayerID: UUID) {
        // Initialize game state
        gameState.initializeMatch(players: players, localPlayerID: localPlayerID)
        
        // Reset match manager state
        isQuizActive = false
        activeAreaIndex = nil
        matchResult = nil
        
        // Calculate initial leaderboard
        refreshLeaderboard()
        
        // Start the countdown
        timerSystem.resetTimer()
        timerSystem.startTimer()
        
        AppLogger.gameplay.info(
            "Match started with \(players.count) player(s). Local player: '\(localPlayerID)'"
        )
    }
    
    /// Convenience method to start a single-player match for testing.
    ///
    /// Creates a match with just the local player. Useful during development
    /// before networking is implemented.
    ///
    /// - Parameter playerName: The display name for the local player.
    func startSinglePlayerMatch(playerName: String) {
        let localID = UUID()
        let player = Player(
            id: localID,
            name: playerName,
            isHost: true,
            isReady: true
        )
        startMatch(players: [player], localPlayerID: localID)
    }
    
    /// Ends the match, calculates the winner, and prepares the results.
    func endMatch() {
        guard gameState.isMatchActive else { return }
        
        // Stop everything
        timerSystem.stopTimer()
        gameState.isMatchActive = false
        gameState.isMatchFinished = true
        
        // Cancel any active quiz
        if isQuizActive {
            quizManager.cancelQuiz()
            isQuizActive = false
            activeAreaIndex = nil
        }
        
        // Calculate final results
        ConquestSystem.updateConqueredCounts(gameState: gameState)
        matchResult = ScoreManager.determineResult(gameState: gameState)
        
        AppLogger.gameplay.info("Match ended. Winner: \(self.matchResult?.winner?.displayName ?? "none")")
    }
    
    // MARK: - Pinpoint Interaction
    
    /// Handles a pinpoint tap from the AR layer.
    ///
    /// Validates whether the local player can attempt the area, and if so,
    /// starts the quiz for that area's topic.
    ///
    /// - Parameter areaIndex: The tapped area index (0–5).
    func handlePinpointTap(areaIndex: Int) {
        guard gameState.isMatchActive else {
            AppLogger.gameplay.debug("Pinpoint tap ignored — match not active")
            return
        }
        
        guard !isQuizActive else {
            AppLogger.gameplay.debug("Pinpoint tap ignored — quiz already active")
            return
        }
        
        let playerID = gameState.localPlayerID
        
        // Check if the player already completed this area (EC-012: allow viewing)
        if let player = gameState.localPlayer, player.completedAreas.contains(areaIndex) {
            AppLogger.gameplay.info("Area \(areaIndex) already attempted — view only")
            // Future: show area info overlay instead of quiz
            return
        }
        
        // Check eligibility
        guard AreaManager.canAttempt(areaIndex: areaIndex, playerID: playerID, gameState: gameState) else {
            return
        }
        
        // Begin the attempt
        AreaManager.beginAttempt(areaIndex: areaIndex, playerID: playerID, gameState: gameState)
        
        // Get the area's topic and seed
        let area = gameState.areas[areaIndex]
        
        // Start the quiz
        quizManager.startQuiz(topic: area.topic, seed: area.questionSeed)
        activeAreaIndex = areaIndex
        isQuizActive = true
        
        AppLogger.gameplay.info("Quiz started for area \(areaIndex) (\(area.topic))")
    }
    
    /// Handles quiz completion. Called by the UI when `QuestionView.onComplete` fires.
    ///
    /// Records the attempt, evaluates conquest, updates visuals, and refreshes the leaderboard.
    ///
    /// - Parameter time: The completion time in seconds.
    func handleQuizCompletion(time: TimeInterval) {
        guard let areaIndex = activeAreaIndex else {
            AppLogger.gameplay.error("Quiz completed but no active area index")
            return
        }
        
        let playerID = gameState.localPlayerID
        
        // Process the conquest
        let result = ConquestSystem.processAttemptResult(
            areaIndex: areaIndex,
            playerID: playerID,
            time: time,
            gameState: gameState
        )
        
        // Log the result
        switch result {
        case .firstClaim(let id):
            AppLogger.gameplay.info("Area \(areaIndex) first claimed by '\(id)'")
        case .conquered(let newID, let oldID):
            AppLogger.gameplay.info("Area \(areaIndex) conquered: '\(newID)' took from '\(oldID)'")
        case .defended(let id):
            AppLogger.gameplay.info("Area \(areaIndex) defended by '\(id)'")
        }
        
        // Clear quiz state
        isQuizActive = false
        activeAreaIndex = nil
        
        // Refresh leaderboard
        refreshLeaderboard()
        
        // Check if all areas are conquered (EC-026: spawn earthquake)
        if gameState.allAreasConquered {
            AppLogger.gameplay.info("All areas conquered — earthquake spawn trigger (Phase 7)")
            // Phase 7 will handle: spawnEarthquakePowerUp()
        }
    }
    
    /// Handles quiz cancellation (e.g., from Tsunami locking the area).
    func handleQuizCancellation() {
        guard isQuizActive else { return }
        
        let playerID = gameState.localPlayerID
        quizManager.cancelQuiz()
        AreaManager.cancelAttempt(playerID: playerID, gameState: gameState)
        
        isQuizActive = false
        activeAreaIndex = nil
        
        AppLogger.gameplay.info("Quiz cancelled for player '\(playerID)'")
    }
    
    // MARK: - Leaderboard
    
    /// Refreshes the leaderboard from current game state.
    private func refreshLeaderboard() {
        leaderboard = ScoreManager.calculateScores(gameState: gameState)
    }
    
    // MARK: - Area Info (for tapping already-completed areas)
    
    /// Returns summary info about an area for display purposes.
    func areaInfo(for index: Int) -> (topic: String, ownerName: String?, bestTime: TimeInterval?)? {
        guard let area = gameState.area(byIndex: index) else { return nil }
        
        let ownerName = area.ownerID.flatMap { ownerIDString -> String? in
            guard let ownerID = UUID(uuidString: ownerIDString) else { return nil }
            return gameState.player(byID: ownerID)?.name
        }
        
        return (topic: area.topic, ownerName: ownerName, bestTime: area.bestTime)
    }
}
