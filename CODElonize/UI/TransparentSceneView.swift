//
//  TransparentSceneView.swift.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 06/07/26.
//

import SwiftUI
import SceneKit

struct TransparentSceneView: UIViewRepresentable {

    let scene: SCNScene

    func makeUIView(context: Context) -> SCNView {

        let view = SCNView()

        view.scene = scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()

        cameraNode.position = SCNVector3(0, 9, 14)
        cameraNode.look(at: SCNVector3Zero)

        scene.rootNode.addChildNode(cameraNode)
        view.pointOfView = cameraNode


        view.backgroundColor = .clear
        view.isOpaque = false

        view.autoenablesDefaultLighting = true
        view.allowsCameraControl = true

        view.isPlaying = true
        view.loops = true

        if let islandNode = scene.rootNode.childNodes.first(where: { $0.camera == nil }) {
            let rotate = SCNAction.repeatForever(
                SCNAction.rotateBy(
                    x: 0,
                    y: .pi * 2,
                    z: 0,
                    duration: 20
                )
            )
            islandNode.runAction(rotate)
        }

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
