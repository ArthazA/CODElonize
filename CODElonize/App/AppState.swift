
import SwiftUI
import Combine
import os

enum AppScreen: Equatable {
    case home
    case lobby
    case islandPreview
    case arPlacement
    case game
    case results
}

class AppState: ObservableObject {

    @Published var currentScreen: AppScreen = .home

    @Published var isHost = false

    @Published var playerName: String = ""
    @Published var playerID = UUID()
    @Published var roomCode: String = ""

    let lobbyManager = LobbyManager()

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

    private func setupPinpointWiring() {
        arSessionManager.$tappedAreaIndex
            .compactMap { $0 }
            .sink { [weak self] areaIndex in
                self?.matchManager.handlePinpointTap(areaIndex: areaIndex)

                self?.arSessionManager.tappedAreaIndex = nil
            }
            .store(in: &cancellables)
    }

    func navigate(to screen: AppScreen) {
        AppLogger.ui.info("Navigating to \(String(describing: screen))")
        currentScreen = screen
    }

    func returnToHome() {
        arSessionManager.resetSession()
        matchManager.gameState.reset()
        matchManager.matchResult = nil
        isHost = false
        currentScreen = .home
        AppLogger.ui.info("Returned to home, session reset")
    }

    func generateRoomCode() {
        roomCode = String(format: "%04d", Int.random(in: 0...9999))
    }
}
