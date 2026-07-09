
import SwiftUI
import RealityKit
import ARKit
import Combine
import os

enum ARSessionState: Equatable {
    case initializing
    case planeDetected
    case islandPlaced
    case failed(String)

    static func == (lhs: ARSessionState, rhs: ARSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.planeDetected, .planeDetected),
             (.islandPlaced, .islandPlaced):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

class ARSessionManager: NSObject, ObservableObject {

    @Published var sessionState: ARSessionState = .initializing

    @Published var isPlaneDetected = false

    @Published var tappedAreaIndex: Int? = nil

    @Published var islandScale: Float = GameConstants.defaultIslandScale

    @Published var islandRotation: Float = 0
    @Published var isPreviewMode = false
    @Published var savedPlacementTransform: simd_float4x4?
    private var previewAnchor: AnchorEntity?

    private let enableAR: Bool
    init(enableAR: Bool = true) {
        self.enableAR = enableAR
        super.init()
    }
    lazy var arView: ARView = {
        let view = ARView(frame: .zero)
            if enableAR {
                configureARView(view)
            }
        return view
    }()

    let islandPlacement = IslandPlacement()

    let pinpointSystem = PinpointSystem()

    private func configureARView(_ view: ARView) {

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            AppLogger.ar.info("Scene depth supported on this device")
        }

        view.session.delegate = self
        view.session.run(configuration)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        #if DEBUG
        view.debugOptions = [.showFeaturePoints]
        #endif

        AppLogger.ar.info("AR session started with horizontal plane detection")
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: arView)

        if isPreviewMode {
            guard savedPlacementTransform == nil else { return }
            placePreviewIslandAtTap(location)
            return
        }

        switch sessionState {
        case .initializing, .planeDetected:
            placeIslandAtTap(location)
        case .islandPlaced:
            detectPinpointTap(location)
        case .failed:
            break
        }
    }

    private func placePreviewIslandAtTap(_ location: CGPoint) {
        guard let result = arView.raycast(
            from: location,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ).first else {
            AppLogger.ar.debug("No horizontal plane at tap location (preview)")
            return
        }

        guard let entity = try? Entity.load(named: "PreviewIslands") else {
            AppLogger.ar.error("Gagal load PreviewIslands.usdz")
            return
        }

        previewAnchor = AnchorEntity(world: result.worldTransform)
        previewAnchor?.addChild(entity)

        arView.scene.addAnchor(previewAnchor!)

        savedPlacementTransform = result.worldTransform
        AppLogger.ar.info("Preview island placed, transform saved")
    }

    func placeIslandUsingSavedTransformIfAvailable() {
        guard let transform = savedPlacementTransform else {
            AppLogger.ar.warning("Belum ada saved transform, fallback ke tap manual")
            return
        }
        guard !islandPlacement.isPlaced else { return }

        do {
            try islandPlacement.placeIsland(
                at: transform,
                in: arView,
                scale: islandScale,
                rotation: islandRotation
            )
            if let anchor = islandPlacement.islandAnchor {
                pinpointSystem.spawnPinpoints(on: anchor)
            }
            sessionState = .islandPlaced
        } catch {
            AppLogger.ar.error("Gagal placing dari saved transform: \(error.localizedDescription)")
            sessionState = .failed(error.localizedDescription)
        }
    }

    private func placeIslandAtTap(_ location: CGPoint) {

        guard let result = arView.raycast(
            from: location,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ).first else {
            AppLogger.ar.debug("No horizontal plane at tap location")
            return
        }

        do {
            try islandPlacement.placeIsland(
                at: result,
                in: arView,
                scale: islandScale,
                rotation: islandRotation
            )

            if let anchor = islandPlacement.islandAnchor {
                pinpointSystem.spawnPinpoints(on: anchor)
            }

            sessionState = .islandPlaced
            AppLogger.ar.info("Island placed successfully")

        } catch {
            AppLogger.ar.error("Failed to place island: \(error.localizedDescription)")
            sessionState = .failed(error.localizedDescription)
        }
    }

    private func detectPinpointTap(_ location: CGPoint) {

        if let entity = arView.entity(at: location) {
            if let areaIndex = pinpointSystem.areaIndex(for: entity) {
                AppLogger.ar.info("Pinpoint tapped: Area \(areaIndex) (\(GameConstants.areaTopics[areaIndex]))")
                tappedAreaIndex = areaIndex
            }
        }
    }

    func updateIslandTransform(scale: Float, rotation: Float) {
        self.islandScale = scale
        self.islandRotation = rotation
        islandPlacement.updateTransform(scale: scale, rotation: rotation)
    }

    func pauseSession() {
        arView.session.pause()
        AppLogger.ar.info("AR session paused")
    }

    func resumeSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
        AppLogger.ar.info("AR session resumed")
    }

    func resetSession() {
        islandPlacement.removeIsland(from: arView)
        pinpointSystem.removeAllPinpoints()
        sessionState = .initializing
        isPlaneDetected = false
        tappedAreaIndex = nil

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])

        AppLogger.ar.info("AR session reset")
    }
    func removePreviewIsland() {
        if let previewAnchor {
            arView.scene.removeAnchor(previewAnchor)
            self.previewAnchor = nil
        }
    }
}

extension ARSessionManager: ARSessionDelegate {

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARPlaneAnchor {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if case .initializing = self.sessionState {
                        self.isPlaneDetected = true
                        self.sessionState = .planeDetected
                        AppLogger.ar.info("Horizontal plane detected")
                    }
                }
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        AppLogger.ar.error("AR session failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .failed(error.localizedDescription)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        AppLogger.ar.warning("AR session was interrupted")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        AppLogger.ar.info("AR session interruption ended, resuming")
    }
}
