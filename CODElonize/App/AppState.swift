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
    case preview
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
    
    /// The AR session manager. The ARView within it is created lazily,
    /// so the camera/session doesn't start until the AR view actually appears.
    let arSessionManager = ARSessionManager()
    
    /// The match manager. Coordinates all gameplay systems (Phase 6).
    /// Injected into the environment for UI views to observe.
    let matchManager = MatchManager()
    
    /// Subscriptions for reactive wiring.
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
        AppLogger.ui.info("Returned to home, session reset")
    }
}
