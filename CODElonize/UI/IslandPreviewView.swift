
import SwiftUI
import RealityKit

struct IslandPreviewView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(arSessionManager: appState.arSessionManager)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    appState.arSessionManager.isPreviewMode = true
                }

            ReadyButtonOverlay(appState: appState)
        }
    }
}
private struct ReadyButtonOverlay: View {
    @ObservedObject var arSessionManager: ARSessionManager
    let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.arSessionManager = appState.arSessionManager
    }

    var body: some View {
        Group {
            if arSessionManager.savedPlacementTransform != nil {
                PrimaryButton(title: "Ready") {
                    arSessionManager.isPreviewMode = false
                    arSessionManager.removePreviewIsland()
                    appState.lobbyManager.setReady(
                        playerID: appState.playerID,
                        isReady: true,
                        isHost: appState.isHost
                    )
                    appState.navigate(to: .lobby)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            } else {
                Text("Tap the ground to preview your island")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    IslandPreviewView()
        .environmentObject(AppState())
}
