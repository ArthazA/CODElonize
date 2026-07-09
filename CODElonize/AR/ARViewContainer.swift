//
//  ARViewContainer.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import SwiftUI
import RealityKit
import ARKit

/// A `UIViewRepresentable` that bridges the RealityKit `ARView` into SwiftUI.
/// The `ARView` instance is owned by `ARSessionManager` and simply returned here.
struct ARViewContainer: UIViewRepresentable {
    
    /// The AR session manager that owns the ARView.
    @ObservedObject var arSessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        arSessionManager.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates are handled reactively by ARSessionManager.
        // No manual view updates needed here.
    }
    
}
