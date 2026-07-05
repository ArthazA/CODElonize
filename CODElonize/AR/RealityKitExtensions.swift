//
//  RealityKitExtensions.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import RealityKit
import UIKit

// MARK: - ModelEntity Helpers

extension ModelEntity {
    
    /// Creates a simple colored sphere entity with a collision shape for tap detection.
    /// - Parameters:
    ///   - radius: The visual radius of the sphere.
    ///   - color: The UIColor to apply as a simple material.
    ///   - collisionRadius: The radius of the collision sphere (defaults to visual radius).
    /// - Returns: A `ModelEntity` with mesh, material, and collision component.
    static func makeSphere(
        radius: Float,
        color: UIColor,
        collisionRadius: Float? = nil
    ) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Add collision shape for hit testing
        let collisionShape = ShapeResource.generateSphere(radius: collisionRadius ?? radius)
        entity.collision = CollisionComponent(shapes: [collisionShape])
        
        return entity
    }
    
    /// Creates a thin cylinder entity (used for pinpoint shafts).
    /// - Parameters:
    ///   - height: The height of the cylinder.
    ///   - radius: The radius of the cylinder.
    ///   - color: The UIColor to apply.
    /// - Returns: A `ModelEntity` cylinder.
    static func makeCylinder(
        height: Float,
        radius: Float,
        color: UIColor
    ) -> ModelEntity {
        let mesh = MeshResource.generateCylinder(height: height, radius: radius)
        let material = SimpleMaterial(color: color, isMetallic: false)
        return ModelEntity(mesh: mesh, materials: [material])
    }
}

// MARK: - Entity Hierarchy Helpers

extension Entity {
    
    /// Walks up the entity hierarchy looking for a pinpoint entity (named "pinpoint_N").
    /// - Returns: The area index if this entity or any ancestor is a pinpoint, nil otherwise.
    func findPinpointAreaIndex() -> Int? {
        var current: Entity? = self
        while let entity = current {
            if entity.name.hasPrefix("pinpoint_"),
               let indexString = entity.name.split(separator: "_").last,
               let index = Int(indexString) {
                return index
            }
            current = entity.parent
        }
        return nil
    }
}
