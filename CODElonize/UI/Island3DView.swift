import SwiftUI
import SceneKit

struct Island3DView: View {
    private var scene: SCNScene? {
        guard let url = Bundle.main.url(forResource: "Islands", withExtension: "usdz") else {
            return nil
        }

        return try? SCNScene(url: url)
    }

    var body: some View {
        Group {
            if let scene {
                TransparentSceneView(scene: scene)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        Text("Island Preview")
                    }
                }
            }
        }
}

#Preview {
    Island3DView()
        .frame(height: 300)
}
