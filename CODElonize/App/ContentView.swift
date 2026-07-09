
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .home:
                Home()

            case .lobby:
                Lobby(isHost: appState.isHost)

            case .islandPreview:
                IslandPreviewView()

            case .arPlacement:
                ARPlacementView()

            case .game:
                GameScreen()

            case .results:
                Results()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        .environmentObject(appState.matchManager)
    }
}

struct ARPlacementView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {

            ARViewContainer(arSessionManager: appState.arSessionManager)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    appState.arSessionManager.isPreviewMode = false
                    appState.arSessionManager.placeIslandUsingSavedTransformIfAvailable()
                }
            
            // Overlay UI
            VStack {

                ARStatusBanner(state: appState.arSessionManager.sessionState)
                    .padding(.top, 50)

                Spacer()

                if appState.arSessionManager.sessionState == .islandPlaced {
                    VStack(spacing: 16) {
                        Text("Island placed! Tap a pinpoint to interact.")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                        HStack(spacing: 20) {
                            Button(action: {
                                appState.arSessionManager.resetSession()
                            }) {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(10)
                            }

                            Button(action: {
                                appState.navigate(to: .game)
                            }) {
                                Label("Continue", systemImage: "play.fill")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.themeDarkTeal)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct ARStatusBanner: View {
    let state: ARSessionState

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)

            Text(statusText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    private var statusText: String {
        switch state {
        case .initializing:
            return "Move your device to detect surfaces..."
        case .planeDetected:
            return "Surface detected! Tap to place the island."
        case .islandPlaced:
            return "Island placed"
        case .failed(let message):
            return "Error: \(message)"
        }
    }

    private var iconName: String {
        switch state {
        case .initializing:
            return "viewfinder"
        case .planeDetected:
            return "hand.tap"
        case .islandPlaced:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .initializing:
            return .yellow
        case .planeDetected:
            return .green
        case .islandPlaced:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
