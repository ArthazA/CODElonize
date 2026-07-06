import SwiftUI
import SceneKit

struct Island3DView: View {
    var body: some View {

        if let url = Bundle.main.url(forResource: "Islands", withExtension: "usdz"),
           let scene = try? SCNScene(url: url) {

            TransparentSceneView(scene: scene)

        } else {

            Text("❌ Failed to load USDZ")

        }
    }
}

#Preview {
    Island3DView()
        .frame(height: 300)
}
