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

    private func placeModelIfNeeded(on anchor: ARPlaneAnchor) {
        guard !isModelPlaced else { return }

        guard let entity = try? Entity.load(named: "PreviewIslands") else {
            print("Gagal load PreviewIslands.usdz")
            return
        }

        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)

        isModelPlaced = true
    }

    func resetSession() {
        arView.session.pause()
        isModelPlaced = false
    }
}

extension IslandPreviewManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async { [weak self] in
                    self?.placeModelIfNeeded(on: planeAnchor)
                }
            }
        }
    }
}
