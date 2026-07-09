
import SwiftUI
import RealityKit

struct ARViewContainer: UIViewRepresentable {

    @ObservedObject var arSessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        return arSessionManager.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }
}
