
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
    
    /// Set by AppState/MatchManager whenever a SwiftUI overlay (quiz, area
    /// picker, area info) is covering the AR view. When true, AR tap-to-place/
    /// tap-to-interact is suppressed so overlay buttons reliably receive touches
    /// instead of racing the UIKit gesture recognizer attached to `arView`.
    @Published var isOverlayBlockingTaps = false

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
        print("🔥 CREATE ARVIEW")
        let view = ARView(frame: .zero)
        if enableAR {
            configureARView(view)
        }
        return view
    }()

    let islandPlacement = IslandPlacement()

    let pinpointSystem = PinpointSystem()
    
    let powerUpEntitySystem = PowerUpEntitySystem()

    @Published var tappedPowerUpID: UUID? = nil
    @Published var tappedEmberMothID: UUID? = nil

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
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        #if DEBUG
        view.debugOptions = [.showFeaturePoints]
        #endif

        AppLogger.ar.info("AR session started with horizontal plane detection")
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard !isOverlayBlockingTaps else { return }
        
        let location = sender.location(in: arView)

        if isPreviewMode {
            placePreviewIslandAtTap(location)
            return
        }

        switch sessionState {
        case .initializing, .planeDetected:
            placeIslandAtTap(location)
        case .islandPlaced:
//            detectPinpointTap(location)
            detectEntityTap(location)
        case .failed:
            break
        }
    }

    private func placePreviewIslandAtTap(_ location: CGPoint) {
        print("Preview tap")
        guard let result = arView.raycast(
            from: location,
            allowing: .existingPlaneInfinite,
            alignment: .horizontal
        ).first else {
            AppLogger.ar.debug("No horizontal plane at tap location (preview)")
            return
        }

        if let previewAnchor {

            print("=== MOVE PREVIEW ===")
            print("Before move anchor scale:", previewAnchor.scale)

            previewAnchor.transform = Transform(matrix: result.worldTransform)

            print("After move anchor scale:", previewAnchor.scale)

            if let entity = previewAnchor.children.first {
                print("Entity scale:", entity.scale)
                print("Bounds:", entity.visualBounds(relativeTo: nil).extents)
            }

        } else {

            guard let entity = try? Entity.load(named: "PreviewIslands") else {
                AppLogger.ar.error("Failed to load PreviewIslands")
                return
            }

            print("=== FIRST CREATE ===")
            print("Original entity scale:", entity.scale)
            print("Original bounds:", entity.visualBounds(relativeTo: nil).extents)

            let bounds = entity.visualBounds(relativeTo: nil)
            let scaledHeight = bounds.extents.y * islandScale

            entity.scale = SIMD3<Float>(repeating: islandScale)
            entity.position.y = -(scaledHeight / 2) - 0.02
            entity.orientation = simd_quatf(angle: islandRotation, axis: [0,1,0])

            let anchor = AnchorEntity(world: result.worldTransform)

            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            previewAnchor = anchor
            print("Anchor transform:", anchor.transform.matrix)
        }
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
            allowing: .existingPlaneInfinite,
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

//    private func detectPinpointTap(_ location: CGPoint) {
//
//        if let entity = arView.entity(at: location) {
//            if let areaIndex = pinpointSystem.areaIndex(for: entity) {
//                AppLogger.ar.info("Pinpoint tapped: Area \(areaIndex) (\(GameConstants.areaTopics[areaIndex]))")
//                tappedAreaIndex = areaIndex
//            }
//        }
//    }
    
    private func detectEntityTap(_ location: CGPoint) {
        guard let entity = arView.entity(at: location) else { return }

        if let areaIndex = pinpointSystem.areaIndex(for: entity) {
            tappedAreaIndex = areaIndex
            return
        }

        if let (id, kind) = entity.findPowerUpSpawnID() {
            if kind == "embermoth" {
                tappedEmberMothID = id
            } else {
                tappedPowerUpID = id
            }
        }
    }

    func updateIslandTransform(scale: Float, rotation: Float) {
        self.islandScale = scale
        self.islandRotation = rotation
        islandPlacement.updateTransform(scale: scale, rotation: rotation)
    }
    
    func syncPowerUps(powerUps: [SpawnedPowerUp], emberMoths: [SpawnedEmberMoth]) {
        guard let anchor = islandPlacement.islandAnchor else { return }
        powerUpEntitySystem.sync(powerUps: powerUps, emberMoths: emberMoths, islandAnchor: anchor)
    }

    func pauseSession() {
        arView.session.pause()
        AppLogger.ar.info("AR session paused")
    }

    func resumeSession() {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal]
//        configuration.environmentTexturing = .automatic
        guard let configuration = arView.session.configuration else { return }
        arView.session.run(configuration)
//        AppLogger.ar.info("AR session resumed")
    }

    func resetSession() {
        islandPlacement.removeIsland(from: arView)
        powerUpEntitySystem.removeAll()
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

extension ARSessionManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        !isOverlayBlockingTaps
    }
}
