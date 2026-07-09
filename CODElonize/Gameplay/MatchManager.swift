
import Foundation
import Combine
import os

class MatchManager: ObservableObject {

    let gameState = GameState()

    let quizManager = QuizManager()

    let timerSystem = TimerSystem()

    let spawnManager = SpawnManager()

    @Published var isQuizActive: Bool = false

    @Published var activeAreaIndex: Int? = nil

    @Published var leaderboard: [PlayerScore] = []

    @Published var matchResult: MatchResult? = nil

    @Published var isAreaPickerActive: Bool = false

    @Published var pendingPowerUpType: PowerUpType? = nil

    @Published var powerUpFeedback: String? = nil

    @Published var isPowerUpResolving: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private var tsunamiUnlockTimers: [Int: AnyCancellable] = [:]

    init() {
        setupTimerExpiry()
        setupArmageddonTrigger()
        setupGameStateObservation()
    }

    private func setupTimerExpiry() {
        timerSystem.onExpired = { [weak self] in
            AppLogger.gameplay.info("Timer expired — ending match")
            self?.endMatch()
        }
    }

    private func setupArmageddonTrigger() {
        timerSystem.$remainingTime
            .sink { [weak self] remaining in
                guard let self = self else { return }
                if remaining <= GameConstants.armageddonRemainingTime,
                   self.gameState.isMatchActive,
                   !self.gameState.armageddonTriggered {

                    self.gameState.armageddonTriggered = true
                    self.gameState.isArmageddonActive = true

                    AreaManager.unlockArea(index: 6, gameState: self.gameState)

                    self.spawnManager.spawnEmberMoth()

                    AppLogger.gameplay.info("Armageddon Phase triggered!")
                }
            }
            .store(in: &cancellables)
    }

    private func setupGameStateObservation() {

        gameState.$areas
            .combineLatest(gameState.$players)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.refreshLeaderboard()
            }
            .store(in: &cancellables)
    }

    func startMatch(players: [Player], localPlayerID: UUID) {

        gameState.initializeMatch(players: players, localPlayerID: localPlayerID)

        isQuizActive = false
        activeAreaIndex = nil
        matchResult = nil
        isAreaPickerActive = false
        pendingPowerUpType = nil
        powerUpFeedback = nil
        isPowerUpResolving = false

        spawnManager.reset()
        tsunamiUnlockTimers.values.forEach { $0.cancel() }
        tsunamiUnlockTimers.removeAll()

        refreshLeaderboard()

        timerSystem.resetTimer()
        timerSystem.startTimer()

        spawnManager.startSpawning()

        AppLogger.gameplay.info(
            "Match started with \(players.count) player(s). Local player: '\(localPlayerID)'"
        )
    }

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

    func endMatch() {
        guard gameState.isMatchActive else { return }

        timerSystem.stopTimer()
        spawnManager.stopSpawning()
        gameState.isMatchActive = false
        gameState.isMatchFinished = true

        if isQuizActive {
            quizManager.cancelQuiz()
            isQuizActive = false
            activeAreaIndex = nil
        }

        isAreaPickerActive = false
        pendingPowerUpType = nil

        tsunamiUnlockTimers.values.forEach { $0.cancel() }
        tsunamiUnlockTimers.removeAll()

        ConquestSystem.updateConqueredCounts(gameState: gameState)
        matchResult = ScoreManager.determineResult(gameState: gameState)

        AppLogger.gameplay.info("Match ended. Winner: \(self.matchResult?.winner?.displayName ?? "none")")
    }

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

        if let player = gameState.localPlayer, player.completedAreas.contains(areaIndex) {
            AppLogger.gameplay.info("Area \(areaIndex) already attempted — view only")

            return
        }

        guard AreaManager.canAttempt(areaIndex: areaIndex, playerID: playerID, gameState: gameState) else {
            return
        }

        AreaManager.beginAttempt(areaIndex: areaIndex, playerID: playerID, gameState: gameState)

        let area = gameState.areas[areaIndex]

        quizManager.startQuiz(topic: area.topic, seed: area.questionSeed)
        activeAreaIndex = areaIndex
        isQuizActive = true

        AppLogger.gameplay.info("Quiz started for area \(areaIndex) (\(area.topic))")
    }

    func handleQuizCompletion(time: TimeInterval) {
        guard let areaIndex = activeAreaIndex else {
            AppLogger.gameplay.error("Quiz completed but no active area index")
            return
        }

        let playerID = gameState.localPlayerID

        let result = ConquestSystem.processAttemptResult(
            areaIndex: areaIndex,
            playerID: playerID,
            time: time,
            gameState: gameState
        )

        switch result {
        case .firstClaim(let id):
            AppLogger.gameplay.info("Area \(areaIndex) first claimed by '\(id)'")
        case .conquered(let newID, let oldID):
            AppLogger.gameplay.info("Area \(areaIndex) conquered: '\(newID)' took from '\(oldID)'")
        case .defended(let id):
            AppLogger.gameplay.info("Area \(areaIndex) defended by '\(id)'")
        }

        isQuizActive = false
        activeAreaIndex = nil

        refreshLeaderboard()

        if gameState.allAreasConquered {
            AppLogger.gameplay.info("All areas conquered — spawning earthquake")
            spawnManager.spawnEarthquake()
        }
    }

    func handleQuizCancellation() {
        guard isQuizActive else { return }

        let playerID = gameState.localPlayerID
        quizManager.cancelQuiz()
        AreaManager.cancelAttempt(playerID: playerID, gameState: gameState)

        isQuizActive = false
        activeAreaIndex = nil

        AppLogger.gameplay.info("Quiz cancelled for player '\(playerID)'")
    }

    func handlePowerUpCollection(spawnID: UUID) {
        let playerID = gameState.localPlayerID

        guard let player = gameState.localPlayer,
              player.inventory.count < GameConstants.maxInventorySize else {
            powerUpFeedback = "Inventory full!"
            clearFeedbackAfterDelay()
            return
        }

        guard let type = spawnManager.attemptClaim(spawnID: spawnID, playerID: playerID) else {
            powerUpFeedback = "Claim failed!"
            clearFeedbackAfterDelay()
            return
        }

        PowerUpManager.addToInventory(type: type, playerID: playerID, gameState: gameState)

        powerUpFeedback = "\(type.displayName) collected!"
        clearFeedbackAfterDelay()
    }

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

    func cancelAreaPicker() {
        isAreaPickerActive = false
        pendingPowerUpType = nil
    }

    func handlePowerUpActivation(targetArea: Int) {
        guard let type = pendingPowerUpType else { return }

        let playerID = gameState.localPlayerID

        isAreaPickerActive = false
        pendingPowerUpType = nil

        isPowerUpResolving = true

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

            if case .success = result {
                scheduleTsunamiUnlock(for: targetArea)

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

        switch result {
        case .success(let description):
            powerUpFeedback = description
            refreshLeaderboard()
        case .failed(let reason):
            powerUpFeedback = reason
        }

        clearFeedbackAfterDelay()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isPowerUpResolving = false
        }
    }

    private func scheduleTsunamiUnlock(for areaIndex: Int) {

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

    private func refreshLeaderboard() {
        leaderboard = ScoreManager.calculateScores(gameState: gameState)
    }

    private func clearFeedbackAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.powerUpFeedback = nil
        }
    }

    func areaInfo(for index: Int) -> (topic: String, ownerName: String?, bestTime: TimeInterval?)? {
        guard let area = gameState.area(byIndex: index) else { return nil }

        let ownerName = area.ownerID.flatMap { ownerIDString -> String? in
            guard let ownerID = UUID(uuidString: ownerIDString) else { return nil }
            return gameState.player(byID: ownerID)?.name
        }

        return (topic: area.topic, ownerName: ownerName, bestTime: area.bestTime)
    }
}
