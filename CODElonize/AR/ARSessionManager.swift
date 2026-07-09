//
//  ARSessionManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import os

/// Represents the current state of the AR session.
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

/// Owns the ARView and manages the full AR lifecycle:
/// plane detection → island placement → pinpoint interaction.
///
/// This is the central coordinator for all AR functionality.
/// It delegates model loading to `IslandPlacement` and pinpoint management to `PinpointSystem`.
class ARSessionManager: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Current state of the AR session.
    @Published var sessionState: ARSessionState = .initializing
    
    /// Whether at least one horizontal plane has been detected.
    @Published var isPlaneDetected = false
    
    /// The index of the most recently tapped pinpoint area (nil if none).
    /// UI layers observe this to open the quiz interface.
    @Published var tappedAreaIndex: Int? = nil
    
    // MARK: - Island Transform (adjustable by host from Lobby)
    
    /// Current island scale factor.
    @Published var islandScale: Float = GameConstants.defaultIslandScale
    
    /// Current island Y-axis rotation in radians.
    @Published var islandRotation: Float = 0
    @Published var isPreviewMode = false
    @Published var savedPlacementTransform: simd_float4x4?
    private var previewAnchor: AnchorEntity?
    
    // MARK: - Internal Components
    
    /// The RealityKit view. Created lazily on first access so the AR session
    /// doesn't start until the view actually appears on screen.
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
    
    /// Handles loading and anchoring the island model.
    let islandPlacement = IslandPlacement()
    
    /// Manages the 6 area pinpoint entities.
    let pinpointSystem = PinpointSystem()
    
    // MARK: - Setup
    
    private func configureARView(_ view: ARView) {
        // Configure the AR session for horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        // Enable collaboration for shared AR (Phase 3)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            AppLogger.ar.info("Scene depth supported on this device")
        }
        
        view.session.delegate = self
        view.session.run(configuration)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Enable debug options during development (disable for release)
        #if DEBUG
        view.debugOptions = [.showFeaturePoints]
        #endif
        
        AppLogger.ar.info("AR session started with horizontal plane detection")
    }
    
    // MARK: - Tap Handling
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: arView)

        if isPreviewMode {
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
    
    /// Attempts to place the island at the tapped location on a detected plane.
    private func placeIslandAtTap(_ location: CGPoint) {
        // Raycast from the tap point to find a horizontal plane
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
            
            // Spawn pinpoints on the island
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
    
    /// Checks if the user tapped on a pinpoint entity.
    private func detectPinpointTap(_ location: CGPoint) {
        // Use RealityKit entity hit testing
        if let entity = arView.entity(at: location) {
            if let areaIndex = pinpointSystem.areaIndex(for: entity) {
                AppLogger.ar.info("Pinpoint tapped: Area \(areaIndex) (\(GameConstants.areaTopics[areaIndex]))")
                tappedAreaIndex = areaIndex
            }
        }
    }
    
    // MARK: - Island Transform (called from Lobby UI)
    
    /// Updates the island's visual transform. Called by the host when adjusting
    /// scale/rotation from the Lobby screen.
    func updateIslandTransform(scale: Float, rotation: Float) {
        self.islandScale = scale
        self.islandRotation = rotation
        islandPlacement.updateTransform(scale: scale, rotation: rotation)
    }
    
    // MARK: - Session Control
    
    /// Pauses the AR session (e.g., when the app enters background).
    func pauseSession() {
        arView.session.pause()
        AppLogger.ar.info("AR session paused")
    }
    
    /// Resumes the AR session with the existing configuration.
    func resumeSession() {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal]
//        configuration.environmentTexturing = .automatic
        guard let configuration = arView.session.configuration else { return }
        arView.session.run(configuration)
//        AppLogger.ar.info("AR session resumed")
    }
    
    /// Completely resets the AR session, removing the island and all anchors.
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

// MARK: - ARSessionDelegate

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
