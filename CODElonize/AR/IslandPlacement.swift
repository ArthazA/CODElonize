//
//  IslandPlacement.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import RealityKit
import ARKit
import os

/// Error types specific to island placement.
enum IslandPlacementError: LocalizedError {
    case modelNotFound
    case modelLoadFailed(Error)
    case alreadyPlaced
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Island model file not found in bundle."
        case .modelLoadFailed(let error):
            return "Failed to load island model: \(error.localizedDescription)"
        case .alreadyPlaced:
            return "Island has already been placed."
        }
    }
}

/// Responsible for loading the Islands.usdz model and anchoring it to a detected AR plane.
/// The host can adjust scale, rotation, and position from the Lobby before the match starts.
class IslandPlacement {
    
    /// The anchor entity that holds the island in the AR scene.
    private(set) var islandAnchor: AnchorEntity?
    
    /// The loaded island model entity (child of the anchor).
    private(set) var islandEntity: Entity?
    
    /// Whether the island has been placed in the scene.
    var isPlaced: Bool { islandAnchor != nil }
    
    // MARK: - Loading
    
    /// Loads the island 3D model from the app bundle.
    /// - Returns: The loaded `Entity` hierarchy.
    /// - Throws: `IslandPlacementError` if the model cannot be found or loaded.
    func loadIslandModel() throws -> Entity {
        // Try loading by name first (searches entire bundle)
        do {
            let entity = try Entity.load(named: GameConstants.islandModelName)
            AppLogger.ar.info("Island model loaded successfully by name")
            return entity
        } catch {
            AppLogger.ar.warning("Failed to load island by name, trying URL: \(error.localizedDescription)")
        }
        
        // Fallback: load by explicit URL
        guard let url = Bundle.main.url(
            forResource: GameConstants.islandModelName,
            withExtension: "usdz"
        ) else {
            throw IslandPlacementError.modelNotFound
        }
        
        do {
            let entity = try Entity.load(contentsOf: url)
            AppLogger.ar.info("Island model loaded successfully from URL")
            return entity
        } catch {
            throw IslandPlacementError.modelLoadFailed(error)
        }
    }
    
    
    // MARK: - Placement
    
    /// Places the island at the given raycast result location in the AR scene.
    /// - Parameters:
    ///   - result: The `ARRaycastResult` from a user tap on a detected plane.
    ///   - arView: The `ARView` to add the island to.
    ///   - scale: The scale factor to apply to the island.
    ///   - rotation: The Y-axis rotation in radians to apply.
    /// - Throws: `IslandPlacementError` if the island is already placed or loading fails.
    func placeIsland(
            at result: ARRaycastResult,
            in arView: ARView,
            scale: Float,
            rotation: Float
        ) throws {
            guard !isPlaced else {
                throw IslandPlacementError.alreadyPlaced
            }

            let model = try loadIslandModel()

            func printHierarchy(_ entity: Entity, level: Int = 0) {
                print(String(repeating: "-", count: level), entity.name)
                for child in entity.children {
                    printHierarchy(child, level: level + 1)
                }
            }
            printHierarchy(model)

            let anchor = AnchorEntity(raycastResult: result)

            let bounds = model.visualBounds(relativeTo: nil)
            AppLogger.ar.info("Island RAW size (before scale): \(bounds.extents)")
            let scaledHeight = bounds.extents.y * scale

            model.scale = SIMD3<Float>(repeating: scale)
            model.position.y = -(scaledHeight / 2) - 0.02
            model.orientation = simd_quatf(angle: rotation, axis: SIMD3<Float>(0, 1, 0))

            anchor.addChild(model)
            arView.scene.addAnchor(anchor)

            self.islandAnchor = anchor
            self.islandEntity = model

            AppLogger.ar.info("Island placed at world position: \(result.worldTransform.columns.3)")
        }

        // MARK: - Placement (dari transform tersimpan — dipakai ulang dari Preview)

        func placeIsland(
            at worldTransform: simd_float4x4,
            in arView: ARView,
            scale: Float,
            rotation: Float
        ) throws {
            guard !isPlaced else {
                throw IslandPlacementError.alreadyPlaced
            }

            let model = try loadIslandModel()
            let anchor = AnchorEntity(world: worldTransform)

            let bounds = model.visualBounds(relativeTo: nil)
            let scaledHeight = bounds.extents.y * scale

            model.scale = SIMD3<Float>(repeating: scale)
            model.position.y = -(scaledHeight / 2) - 0.02
            model.orientation = simd_quatf(angle: rotation, axis: SIMD3<Float>(0, 1, 0))

            anchor.addChild(model)
            arView.scene.addAnchor(anchor)

            self.islandAnchor = anchor
            self.islandEntity = model

            AppLogger.ar.info("Island placed from saved transform")
        }
        
        // MARK: - Transform Updates
        
        /// Updates the island's scale and rotation. Called when the host adjusts settings from the Lobby.
        /// - Parameters:
        ///   - scale: New scale factor.
        ///   - rotation: New Y-axis rotation in radians.
    func updateTransform(scale: Float, rotation: Float) {
        guard let island = islandEntity else { return }
        
        let bounds = island.visualBounds(relativeTo: nil)
        let currentScale = island.scale.x
        let baseHeight = bounds.extents.y / max(currentScale, 0.0001)
        let scaledHeight = baseHeight * scale

        island.scale = SIMD3<Float>(repeating: scale)
        island.position.y = -(scaledHeight / 2) - 0.02
        island.orientation = simd_quatf(angle: rotation, axis: [0,1,0])
        AppLogger.ar.debug("Island transform updated — scale: \(scale), rotation: \(rotation)")
    }
        
        /// Moves the island anchor to a new world position.
        /// Used when the host repositions the island from the Lobby.
        /// - Parameter newTransform: The new world transform for the anchor.
        func moveIsland(to newTransform: simd_float4x4) {
            guard let anchor = islandAnchor else { return }
            anchor.transform = Transform(matrix: newTransform)
            AppLogger.ar.debug("Island moved to new position")
        }
        
        // MARK: - Removal
        
        /// Removes the island and its anchor from the AR scene.
        /// - Parameter arView: The `ARView` to remove from.
        func removeIsland(from arView: ARView) {
            if let anchor = islandAnchor {
                arView.scene.removeAnchor(anchor)
            }
            islandAnchor = nil
            islandEntity = nil
            AppLogger.ar.info("Island removed from scene")
        }
    }

