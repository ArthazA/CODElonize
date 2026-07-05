import SwiftUI
import SceneKit

struct Island3DView: View {
    var body: some View {
        // Attempt to load the Island model. 
        // If it fails to load, it will show an empty view, but you can also provide a fallback.
        if let scene = SCNScene(named: "Models/Islands.usdz") {
            SceneView(
                scene: scene,
                options: [.autoenablesDefaultLighting, .allowsCameraControl]
            )
        } else {
            // Fallback to Image if the 3D model is not bundled correctly
            ZStack {
                Color.black.opacity(0.1)
                Text("3D Model Placeholder")
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    Island3DView()
        .frame(height: 300)
}
