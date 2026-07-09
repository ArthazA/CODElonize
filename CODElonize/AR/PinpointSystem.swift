//
//  PinpointSystem.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import RealityKit
import UIKit
import os

class PinpointSystem {
    
    private(set) var pinpoints: [Entity] = []
    
    /// Color palette for each area's pinpoint marker.
    ///
    /// FIX (README §5.1): this previously only had 6 entries while
    /// `GameConstants.areaCount == 7`, which caused `areaColors[6]` to index
    /// out of bounds and crash as soon as area 6 (Frameworks / Armageddon area)
    /// was spawned. A 7th color has been added below.
    ///
    /// FIX (README §5.7): comments now reflect the canonical 7-topic list
    /// (`SwiftUI, Algorithms, Data Structures, Networking, Databases, OOP,
    /// Frameworks`, matching `GameConstants.areaTopics`) instead of the stale
    /// 6-topic naming (`Algorithms, AI, Cybersecurity, OOP, Computer Networks,
    /// Database`) that no longer corresponds to anything in the project.
    private let areaColors: [UIColor] = [
        .systemRed,       // Area 0 — SwiftUI (Mountain)
        .systemPurple,    // Area 1 — Algorithms (Forest East)
        .systemGreen,     // Area 2 — Data Structures (Forest West)
        .systemBlue,      // Area 3 — Networking (River)
        .systemOrange,    // Area 4 — Databases (Village)
        .systemYellow,    // Area 5 — OOP (Center)
        .systemTeal,      // Area 6 — Frameworks (Armageddon-locked)
    ]
    
    // MARK: - Spawning
    
    /// Creates and attaches pinpoint entities to the island anchor.
    /// Each pinpoint is a small colored sphere positioned above its area.
    /// - Parameter islandAnchor: The `AnchorEntity` holding the island model.
    func spawnPinpoints(on islandAnchor: AnchorEntity) {
        removeAllPinpoints()
        
        let safeCount = min(
            GameConstants.areaCount,
            GameConstants.pinpointPositions.count,
            areaColors.count
        )
        
        for index in 0..<safeCount {
            let pinpoint = createPinpointEntity(
                areaIndex: index,
                position: GameConstants.pinpointPositions[index],
                color: areaColors[index]
            )
            islandAnchor.addChild(pinpoint)
            pinpoints.append(pinpoint)
        }
        
        AppLogger.ar.info("Spawned \(safeCount) pinpoints on island")
    }
    
    // MARK: - Pinpoint Creation
    
    /// Creates a single pinpoint entity consisting of a sphere marker and a thin shaft.
    /// - Parameters:
    ///   - areaIndex: The index of the area (0-6).
    ///   - position: The 3D position relative to the island anchor.
    ///   - color: The color of the pinpoint marker.
    /// - Returns: A parent `Entity` containing the pinpoint visuals.
    private func createPinpointEntity(
        areaIndex: Int,
        position: SIMD3<Float>,
        color: UIColor
    ) -> Entity {
        // Parent entity for the entire pinpoint assembly
        let pinpointRoot = Entity()
        pinpointRoot.name = "pinpoint_\(areaIndex)"
        pinpointRoot.position = position
        
        // Sphere head (the tappable marker)
        let sphere = ModelEntity.makeSphere(
            radius: GameConstants.pinpointVisualRadius,
            color: color,
            collisionRadius: GameConstants.pinpointCollisionRadius
        )
        sphere.position = SIMD3<Float>(0, 0, 0)
        pinpointRoot.addChild(sphere)
        
        // Thin shaft below the sphere
        let shaftHeight: Float = 0.015
        let shaft = ModelEntity.makeCylinder(
            height: shaftHeight,
            radius: 0.001,
            color: .darkGray
        )
        shaft.position = SIMD3<Float>(0, -(shaftHeight / 2 + GameConstants.pinpointVisualRadius), 0)
        pinpointRoot.addChild(shaft)
        
        return pinpointRoot
    }
    
    // MARK: - Tap Detection
    
    /// Determines if the given entity (or any of its ancestors) is a pinpoint.
    /// - Parameter entity: The entity returned from a hit test.
    /// - Returns: The area index if the entity belongs to a pinpoint, nil otherwise.
    func areaIndex(for entity: Entity) -> Int? {
        return entity.findPinpointAreaIndex()
    }
    
    // MARK: - Visual Updates
    
    /// Updates the visual appearance of a pinpoint to reflect ownership.
    /// - Parameters:
    ///   - areaIndex: The area index to update.
    ///   - ownerColor: The color representing the owner (nil to reset to default).
    func updatePinpointAppearance(areaIndex: Int, ownerColor: UIColor?) {
        guard areaIndex < pinpoints.count else { return }
        
        let pinpoint = pinpoints[areaIndex]
        
        // Find the sphere child and update its material
        if let sphere = pinpoint.children.first as? ModelEntity {
            let color = ownerColor ?? areaColors[areaIndex]
            sphere.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
        }
    }
    
    // MARK: - Removal
    
    /// Removes all pinpoint entities from the scene.
    func removeAllPinpoints() {
        for pinpoint in pinpoints {
            pinpoint.removeFromParent()
        }
        pinpoints.removeAll()
        AppLogger.ar.debug("All pinpoints removed")
    }
}
