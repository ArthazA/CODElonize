//
//  IslandPreviewManager.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 07/07/26.
//

import RealityKit
import ARKit
import Combine

final class IslandPreviewManager: NSObject, ObservableObject {

    @Published var isModelPlaced = false
    @Published var selectedTransform: simd_float4x4?

    private var islandAnchor: AnchorEntity?
    private var islandEntity: Entity?
    
    lazy var arView: ARView = {
        let view = ARView(frame: .zero)
        configure(view)
        return view
    }()

    private func configure(_ view: ARView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        view.session.delegate = self
        view.session.run(configuration)
    }
    
    func placeOrMoveIsland(to result: ARRaycastResult) {
        selectedTransform = result.worldTransform
        if islandAnchor == nil {
            guard let entity = try? Entity.load(named: "PreviewIslands") else {
                return
            }
            entity.scale = SIMD3<Float>(repeating: 0.003)
            let anchor = AnchorEntity(world: result.worldTransform)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            islandAnchor = anchor
            islandEntity = entity
            isModelPlaced = true

        } else {
            islandAnchor?.transform =
                Transform(matrix: result.worldTransform)
        }

    }

    func resetSession() {
        arView.session.pause()
        isModelPlaced = false
    }
}

extension IslandPreviewManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    }
}
