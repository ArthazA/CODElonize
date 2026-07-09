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
//    private let areaColors: [UIColor] = [
//        .systemRed,       // Area 0 — SwiftUI (Mountain)
//        .systemPurple,    // Area 1 — Algorithms (Forest East)
//        .systemGreen,     // Area 2 — Data Structures (Forest West)
//        .systemBlue,      // Area 3 — Networking (River)
//        .systemOrange,    // Area 4 — Databases (Village)
//        .systemYellow,    // Area 5 — OOP (Center)
//        .systemTeal,      // Area 6 — Frameworks (Armageddon-locked)
//    ]

    private let areaColors: [UIColor] = Array(
        repeating: .systemYellow,
        count: GameConstants.areaCount
    )

    private let areaNames = [
        "Mountain",
        "Village",
        "Castle",
        "Riverside",
        "Shipwreck",
        "Desert",
        "Area 7"
    ]
    
    // MARK: - Spawning
    
    /// Creates and attaches pinpoint entities to the island anchor.
    /// Each pinpoint is a small colored sphere positioned above its area.
    /// - Parameter islandAnchor: The `AnchorEntity` holding the island model.
    func spawnPinpoints(on islandEntity: Entity) {
        removeAllPinpoints()
        let safeCount = min(GameConstants.areaCount, areaColors.count)
        for index in 0..<safeCount {
            guard let area = islandEntity.findEntity(named: "Area_\(index + 1)") else {
                AppLogger.ar.warning("Area_\(index + 1) not found")
                continue
            }
            let pinpoint = createPinpointEntity(
                areaIndex: index,
                position: .zero,
                color: areaColors[index]
            )
            
            pinpoint.position.y += 0.5
            area.addChild(pinpoint)
            if let sphere = pinpoint.children.first as? ModelEntity,
               let collision = sphere.components[CollisionComponent.self] {
                print("🔍 Collision shapes count:", collision.shapes.count)   // <- ini kuncinya
            } else {
                print("🔍 No CollisionComponent or not ModelEntity")
            }
            print("Pinpoint collision:", pinpoint.components[CollisionComponent.self] != nil)
            print("Area:", area.name)
            print("Area world:", area.position(relativeTo: nil))
            print("Pinpoint world:", pinpoint.position(relativeTo: nil))

            if let sphere = pinpoint.children.first {
                print("Sphere collision:", sphere.components[CollisionComponent.self] != nil)
            }
            pinpoints.append(pinpoint)
        }
        AppLogger.ar.info("Spawned \(self.pinpoints.count) pinpoints")
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
        let pinpointRoot = Entity()
        pinpointRoot.name = "pinpoint_\(areaIndex)"
        pinpointRoot.position = position
        
        let sphere = ModelEntity.makeSphere(
            radius: GameConstants.pinpointVisualRadius,
            color: color,
            collisionRadius: GameConstants.pinpointCollisionRadius
        )
        sphere.position = SIMD3<Float>(0, 0, 0)
        pinpointRoot.addChild(sphere)
        
        let sphereRadius = GameConstants.pinpointVisualRadius
        let shaftHeight = sphereRadius * 2.5
        let shaftRadius = sphereRadius * 0.18
        
        let shaft = ModelEntity.makeCylinder(
            height: shaftHeight,
            radius: shaftRadius,
            color: UIColor(named: "ThemeDarkTeal") ?? .systemTeal
        )
        shaft.position = SIMD3<Float>(0, -(shaftHeight / 2 + sphereRadius), 0)
        pinpointRoot.addChild(shaft)

        let label = makeLabel(text: areaNames[areaIndex])
        label.position = SIMD3<Float>(0, 0.04, 0)
        pinpointRoot.addChild(label)

        return pinpointRoot
    }

    
    private func makeLabel(text: String) -> ModelEntity {

        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.003,
            font: .systemFont(ofSize: 100, weight: .bold),
            containerFrame: CGRect(x: 0, y: 0, width: 500, height: 100),
            alignment: .center,
            lineBreakMode: .byClipping
        )

        let material = SimpleMaterial(
            color: .white,
            isMetallic: false
        )

        let label = ModelEntity(
            mesh: mesh,
            materials: [material]
        )

        label.scale = SIMD3<Float>(repeating: 0.0015)

        label.position = [0,0.12,0]

        label.orientation = simd_quatf(
            angle: .pi,
            axis: [0,1,0]
        )

        print("Label bounds:", label.visualBounds(relativeTo: nil).extents)

        return label
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
    // MARK: - Overlay Data Access

    /// Data ringan yang dibutuhkan SwiftUI overlay untuk menampilkan label per pinpoint.
    struct PinpointInfo {
        let areaIndex: Int
        let name: String
        let entity: Entity
    }

    /// Mengembalikan info semua pinpoint yang sedang aktif, untuk dipakai proyeksi ke layar.
    func allPinpointInfo() -> [PinpointInfo] {
        pinpoints.enumerated().map { index, entity in
            PinpointInfo(areaIndex: index, name: areaNames[index], entity: entity)
        }
    }
}
