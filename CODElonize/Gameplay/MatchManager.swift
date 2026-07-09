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
/// It owns the `GameState`, `QuizManager`, `TimerSystem`, and `SpawnManager`,
/// and orchestrates the full gameplay loop:
/// pinpoint tap → quiz → time recording → conquest → leaderboard → power-ups.
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
    
    /// Power-up spawning system (Phase 7).
    let spawnManager = SpawnManager()
    
    // MARK: - Published UI State
    
    /// Whether the quiz overlay is currently showing.
    @Published var isQuizActive: Bool = false
    
    /// The area index currently being quizzed (nil if no quiz active).
    @Published var activeAreaIndex: Int? = nil
    
    /// Live sorted leaderboard for the HUD.
    @Published var leaderboard: [PlayerScore] = []
    
    /// The final match result (set when the match finishes).
    @Published var matchResult: MatchResult? = nil
    
    /// Whether the area picker overlay is showing (for power-up activation).
    @Published var isAreaPickerActive: Bool = false
    
    /// The power-up type currently being targeted (waiting for area selection).
    @Published var pendingPowerUpType: PowerUpType? = nil
    
    /// Feedback message from the most recent power-up activation.
    @Published var powerUpFeedback: String? = nil
    
    /// Whether a power-up is currently resolving (blocks new activations, EC-020).
    @Published var isPowerUpResolving: Bool = false
    
    /// Whether this device is the host for the current match.
    ///
    /// SCAFFOLD (README §6.1): host-authoritative sync means only the host
    /// should actually *compute* conquest/power-up/score results; clients
    /// should receive and apply results instead of recomputing them locally.
    /// This flag is threaded through so that split can be implemented once
    /// your teammate's transport contract (README §7) exists. It intentionally
    /// does NOT gate any gameplay logic yet — doing so before there's an
    /// "apply event received from host" pathway on the client would just
    /// make clients silently do nothing. Defaults to `true` so the existing
    /// single-player/dev fallback (§5.8/§8.5) keeps working unmodified.
    @Published var isHost: Bool = true
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Timer for Tsunami unlock scheduling.
    private var tsunamiUnlockTimers: [Int: AnyCancellable] = [:]
    
    // MARK: - Initialization
    
    init() {
        setupTimerExpiry()
        setupArmageddonTrigger()
        setupGameStateObservation()
        forwardChildPublishers()
    }
    
    /// Wires the timer's expiry callback to end the match.
    private func setupTimerExpiry() {
        timerSystem.onExpired = { [weak self] in
            AppLogger.gameplay.info("Timer expired — ending match")
            self?.endMatch()
        }
    }
    
    /// Monitors the countdown timer to trigger Armageddon Phase.
    private func setupArmageddonTrigger() {
        timerSystem.$remainingTime
            .sink { [weak self] remaining in
                guard let self = self else { return }
                if remaining <= GameConstants.armageddonRemainingTime,
                   self.gameState.isMatchActive,
                   !self.gameState.armageddonTriggered {
                    
                    self.gameState.armageddonTriggered = true
                    self.gameState.isArmageddonActive = true
                    
                    // Unlock the 7th area (index 6)
                    AreaManager.unlockArea(index: 6, gameState: self.gameState)
                    
                    // Spawn the first Ember Moth
                    self.spawnManager.spawnEmberMoth()
                    
                    AppLogger.gameplay.info("Armageddon Phase triggered!")
                }
            }
            .store(in: &cancellables)
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
    
    /// Forwards `objectWillChange` from every owned sub-manager up through
    /// `MatchManager`'s own `objectWillChange`.
    ///
    /// FIX (README §5.2): `AppState` already does this for `lobbyManager`,
    /// but `MatchManager` never did it for `spawnManager`, `timerSystem`, or
    /// `quizManager`. Since `GameScreen`/`HUD` only observe `matchManager`
    /// via `@EnvironmentObject`, SwiftUI only re-rendered when *MatchManager's
    /// own* `@Published` properties changed — not when e.g.
    /// `spawnManager.spawnedPowerUps` or `timerSystem.remainingTime` mutated
    /// internally. That's the actual root cause behind both "power-ups only
    /// seem to appear after Armageddon" and "the timer only seems to update
    /// on interaction" — the underlying systems were ticking/spawning
    /// correctly the whole time, the view just was never told to redraw
    /// until something else (like a pinpoint tap) happened to touch
    /// `MatchManager`'s own published state. This must be fixed before
    /// building anything new on top of these systems (per §5.2/§9 step 2),
    /// which is why it's wired here in `init()`.
    private func forwardChildPublishers() {
        spawnManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        timerSystem.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        quizManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Match Lifecycle
    
    /// Starts a new match with the given players.
    ///
    /// - Parameters:
    ///   - players: The players participating in the match.
    ///   - localPlayerID: The ID of the player on this device.
    ///   - isHost: Whether this device is the host for the match. Defaults to
    ///     `true` to preserve existing single-player/dev-fallback behavior.
    ///   - startTime: A shared match-start epoch (e.g. from `StartGameMessage`),
    ///     used to drive the timer in self-correcting shared-timestamp mode
    ///     (README §6.2). Pass `nil` to fall back to local per-device decrementing
    ///     (single-player/dev mode).
    ///   - questionSeeds: 7 host-generated seeds (one per area) so every device
    ///     gets identical randomized question sets per area (README §6.3).
    ///     Pass `nil` to let each area generate its own local seed
    ///     (single-player/dev mode — fine, since there's only one device).
    func startMatch(
        players: [Player],
        localPlayerID: UUID,
        isHost: Bool = true,
        startTime: Date? = nil,
        questionSeeds: [UInt64]? = nil
    ) {
        self.isHost = isHost
        
        // Initialize game state (using shared seeds if provided — §6.3)
        gameState.initializeMatch(players: players, localPlayerID: localPlayerID, questionSeeds: questionSeeds)
        
        // Reset match manager state
        isQuizActive = false
        activeAreaIndex = nil
        matchResult = nil
        isAreaPickerActive = false
        pendingPowerUpType = nil
        powerUpFeedback = nil
        isPowerUpResolving = false
        
        // Reset power-up systems
        spawnManager.reset()
        tsunamiUnlockTimers.values.forEach { $0.cancel() }
        tsunamiUnlockTimers.removeAll()
        
        // Calculate initial leaderboard
        refreshLeaderboard()
        
        // Start the countdown — shared-timestamp mode if a start time was
        // provided (multiplayer), local decrement mode otherwise (dev/single-player).
        if let startTime {
            timerSystem.start(from: startTime, duration: GameConstants.matchDuration)
        } else {
            timerSystem.resetTimer()
            timerSystem.startTimer()
        }
        
        // Start power-up spawning
        spawnManager.startSpawning()
        
        AppLogger.gameplay.info(
            "Match started with \(players.count) player(s). Local player: '\(localPlayerID)', isHost: \(isHost)"
        )
    }
    
    /// Convenience method to start a single-player match for testing.
    ///
    /// Creates a match with just the local player. Useful during development
    /// before networking is implemented. Kept intentionally as a permanent
    /// dev/testing fallback per README §8.5's recommendation.
    ///
    /// - Parameter playerName: The display name for the local player.
    func startSinglePlayerMatch(playerName: String) {
        let localID = UUID()
        let player = Player(
            id: localID,
            name: playerName,
            avatar: "🦊",
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
        spawnManager.stopSpawning()
        gameState.isMatchActive = false
        gameState.isMatchFinished = true
        
        // Cancel any active quiz
        if isQuizActive {
            quizManager.cancelQuiz()
            isQuizActive = false
            activeAreaIndex = nil
        }
        
        // Cancel area picker if open
        isAreaPickerActive = false
        pendingPowerUpType = nil
        
        // Cancel tsunami timers
        tsunamiUnlockTimers.values.forEach { $0.cancel() }
        tsunamiUnlockTimers.removeAll()
        
        // Calculate final results
        //
        // SCAFFOLD (README §6.1): once the sync contract exists, only the
        // host should compute this and broadcast the result; clients should
        // apply a received `MatchResult` instead. Left unconditional for now
        // since there is no "apply received result" pathway yet to fall back to.
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
        
        guard !isAreaPickerActive else {
            AppLogger.gameplay.debug("Pinpoint tap ignored — area picker active")
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
        //
        // SCAFFOLD (README §6.1): under host-authoritative sync, a client
        // should send this attempt result *up* to the host instead of
        // computing conquest locally; only the host calls
        // `ConquestSystem.processAttemptResult` and then broadcasts the
        // outcome. Left unconditional (host-and-client both compute locally)
        // until that transport exists, per §6.1's own note that this is
        // blocked on the teammate's sync contract.
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
            AppLogger.gameplay.info("All areas conquered — spawning earthquake")
            spawnManager.spawnEarthquake()
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
    
    // MARK: - Power-Up Collection
    
    /// Handles tapping a spawned power-up to collect it.
    ///
    /// - Parameter spawnID: The UUID of the spawned power-up.
    func handlePowerUpCollection(spawnID: UUID) {
        let playerID = gameState.localPlayerID
        
        // Check inventory capacity
        guard let player = gameState.localPlayer,
              player.inventory.count < GameConstants.maxInventorySize else {
            powerUpFeedback = "Inventory full!"
            clearFeedbackAfterDelay()
            return
        }
        
        // Attempt claim from spawn manager using new probability mechanic
        guard let type = spawnManager.attemptClaim(spawnID: spawnID, playerID: playerID) else {
            powerUpFeedback = "Claim failed!"
            clearFeedbackAfterDelay()
            return
        }
        
        // Add to player inventory
        PowerUpManager.addToInventory(type: type, playerID: playerID, gameState: gameState)
        
        powerUpFeedback = "\(type.displayName) collected!"
        clearFeedbackAfterDelay()
    }
    
    /// Handles tapping a spawned Ember Moth to collect it.
    ///
    /// - Parameter spawnID: The UUID of the spawned Ember Moth.
    func handleEmberMothCollection(spawnID: UUID) {
        let playerID = gameState.localPlayerID
        
        if spawnManager.attemptEmberMothClaim(mothID: spawnID, playerID: playerID) {
            gameState.awardEmberMothPoints(playerID: playerID)
            refreshLeaderboard()
            
            powerUpFeedback = "Ember Moth collected! +0.5 pts"
        } else {
            powerUpFeedback = "Moth claim failed!"
        }
        
        clearFeedbackAfterDelay()
    }
    
    // MARK: - Power-Up Activation
    
    /// Opens the area picker for a power-up from the player's inventory.
    ///
    /// - Parameter type: The power-up type to activate.
    func startAreaPicker(for type: PowerUpType) {
        guard !isPowerUpResolving else {
            powerUpFeedback = "Wait for current power-up to resolve"
            clearFeedbackAfterDelay()
            return
        }
        
        guard !isQuizActive else {
            powerUpFeedback = "Can't use power-ups during a quiz"
            clearFeedbackAfterDelay()
            return
        }
        
        pendingPowerUpType = type
        isAreaPickerActive = true
    }
    
    /// Cancels the area picker without activating anything.
    func cancelAreaPicker() {
        isAreaPickerActive = false
        pendingPowerUpType = nil
    }
    
    /// Activates the pending power-up on the selected target area.
    ///
    /// - Parameter targetArea: The area index to target.
    func handlePowerUpActivation(targetArea: Int) {
        guard let type = pendingPowerUpType else { return }
        
        let playerID = gameState.localPlayerID
        
        // Close the picker
        isAreaPickerActive = false
        pendingPowerUpType = nil
        
        // Mark as resolving (EC-020: block concurrent activations)
        isPowerUpResolving = true
        
        // Execute the effect
        let result: ActivationResult
        switch type {
        case .earthquake:
            result = PowerUpManager.activateEarthquake(
                playerID: playerID,
                targetArea: targetArea,
                gameState: gameState
            )
            
        case .tsunami:
            result = PowerUpManager.activateTsunami(
                playerID: playerID,
                targetArea: targetArea,
                gameState: gameState
            )
            // If successful, schedule the unlock timer
            if case .success = result {
                scheduleTsunamiUnlock(for: targetArea)
                // Kick any player currently quizzing this area
                if let localArea = activeAreaIndex, localArea == targetArea {
                    handleQuizCancellation()
                }
            }
            
        case .pocketWatch:
            result = PowerUpManager.activatePocketWatch(
                playerID: playerID,
                targetArea: targetArea,
                gameState: gameState
            )
        }
        
        // Process result
        switch result {
        case .success(let description):
            powerUpFeedback = description
            refreshLeaderboard()
        case .failed(let reason):
            powerUpFeedback = reason
        }
        
        clearFeedbackAfterDelay()
        
        // Unblock after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isPowerUpResolving = false
        }
    }
    
    // MARK: - Tsunami Unlock Timer
    
    /// Schedules an automatic unlock for a Tsunami-locked area.
    private func scheduleTsunamiUnlock(for areaIndex: Int) {
        // Cancel existing timer for this area if any (EC-023: renew)
        tsunamiUnlockTimers[areaIndex]?.cancel()
        
        tsunamiUnlockTimers[areaIndex] = Just(())
            .delay(for: .seconds(GameConstants.tsunamiLockDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                AreaManager.unlockArea(index: areaIndex, gameState: self.gameState)
                self.tsunamiUnlockTimers.removeValue(forKey: areaIndex)
                AppLogger.gameplay.info("Area \(areaIndex) auto-unlocked after Tsunami")
            }
    }
    
    // MARK: - Leaderboard
    
    /// Refreshes the leaderboard from current game state.
    private func refreshLeaderboard() {
        leaderboard = ScoreManager.calculateScores(gameState: gameState)
    }
    
    // MARK: - Feedback
    
    /// Clears the power-up feedback message after a delay.
    private func clearFeedbackAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.powerUpFeedback = nil
        }
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
