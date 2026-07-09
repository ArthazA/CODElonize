
import SwiftUI
import SceneKit

struct TransparentSceneView: UIViewRepresentable {

    let scene: SCNScene

    func makeUIView(context: Context) -> SCNView {

        let view = SCNView()

        view.scene = scene

        scene.rootNode.scale = SCNVector3(1.5, 1.5, 1.5)

        view.backgroundColor = .clear
        view.isOpaque = false

        view.autoenablesDefaultLighting = true
        view.allowsCameraControl = true

        let rotate = CABasicAnimation(keyPath: "rotation")
        rotate.fromValue = SCNVector4(0, 1, 0, 0)
        rotate.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        rotate.duration = 20
        rotate.repeatCount = .infinity
        rotate.isRemovedOnCompletion = false

        scene.rootNode.addAnimation(rotate, forKey: "rotate")

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
