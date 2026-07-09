//
//  AppState.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import SwiftUI
import Combine
import os

/// The screens available in the app navigation flow.
enum AppScreen: Equatable {
    case home
    case lobby
    case islandPreview
    case arPlacement
    case game
    case results
}

/// Global application state shared across the entire app via `@EnvironmentObject`.
/// Holds the current navigation state and references to core managers.
class AppState: ObservableObject {
    
    /// The currently displayed screen.
    @Published var currentScreen: AppScreen = .home
    
    /// Whether this device is the host of the current lobby/match.
    @Published var isHost = false
    
    /// The local player's display name.
    @Published var playerName: String = ""
    @Published var playerID = UUID()
    @Published var roomCode: String = ""
    
    let lobbyManager = LobbyManager()
    /// The AR session manager. The ARView within it is created lazily,
    /// so the camera/session doesn't start until the AR view actually appears.
    let arSessionManager: ARSessionManager
    let matchManager = MatchManager()
    
    private var cancellables = Set<AnyCancellable>()
    init(preview: Bool = false) {
        self.arSessionManager = ARSessionManager(enableAR: !preview)

        lobbyManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        setupPinpointWiring()
    }
    
    // MARK: - Reactive Wiring
    
    /// Connects AR pinpoint taps to the match manager.
    ///
    /// When `ARSessionManager.tappedAreaIndex` changes (player tapped a pinpoint
    /// in AR), it routes to `MatchManager.handlePinpointTap` to start the quiz flow.
    private func setupPinpointWiring() {
        arSessionManager.$tappedAreaIndex
            .compactMap { $0 }
            .sink { [weak self] areaIndex in
                self?.matchManager.handlePinpointTap(areaIndex: areaIndex)
                // Reset the tap so it can fire again
                self?.arSessionManager.tappedAreaIndex = nil
            }
            .store(in: &cancellables)
        
        arSessionManager.$tappedPowerUpID
            .compactMap { $0 }
            .sink { [weak self] id in
                self?.matchManager.handlePowerUpCollection(spawnID: id)
                self?.arSessionManager.tappedPowerUpID = nil
            }
            .store(in: &cancellables)

        arSessionManager.$tappedEmberMothID
            .compactMap { $0 }
            .sink { [weak self] id in
                self?.matchManager.handleEmberMothCollection(spawnID: id)
                self?.arSessionManager.tappedEmberMothID = nil
            }
            .store(in: &cancellables)

        matchManager.spawnManager.$spawnedPowerUps
            .combineLatest(matchManager.spawnManager.$spawnedEmberMoths)
            .sink { [weak self] powerUps, moths in
                self?.arSessionManager.syncPowerUps(powerUps: powerUps, emberMoths: moths)
            }
            .store(in: &cancellables)
        
        matchManager.$isQuizActive
            .combineLatest(matchManager.$isAreaPickerActive, matchManager.$isAreaInfoActive)
            .map { quiz, picker, info in quiz || picker || info }
            .removeDuplicates()
            .sink { [weak self] blocking in
                self?.arSessionManager.isOverlayBlockingTaps = blocking
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation
    
    /// Navigates to a new screen.
    func navigate(to screen: AppScreen) {
        AppLogger.ui.info("Navigating to \(String(describing: screen))")
        currentScreen = screen
    }
    
    /// Resets the app back to the home screen and clears session state.
    func returnToHome() {
        arSessionManager.resetSession()
        matchManager.gameState.reset()
        matchManager.matchResult = nil
        isHost = false
        currentScreen = .home
        // Clear any stale match-start payload so the next match doesn't
        // accidentally reuse a previous game's start time/seeds (README §6.3).
        lobbyManager.clearMatchStart()
        AppLogger.ui.info("Returned to home, session reset")
    }
    
    func generateRoomCode() {
        roomCode = String(format: "%04d", Int.random(in: 0...9999))
    }
}
