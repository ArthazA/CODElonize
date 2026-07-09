
import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {

    @ObservedObject var arSessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        arSessionManager.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }
    
}
