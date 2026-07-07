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
    
    private var cancellables = Set<AnyCancellable>()
    init(preview: Bool = false) {
        self.arSessionManager = ARSessionManager(enableAR: !preview)

        lobbyManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
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
        isHost = false
        currentScreen = .home
        AppLogger.ui.info("Returned to home, session reset")
    }
    
    func generateRoomCode() {
        roomCode = String(format: "%04d", Int.random(in: 0...9999))
    }
}
