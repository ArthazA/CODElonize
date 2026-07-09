
import RealityKit
import UIKit

extension ModelEntity {

    static func makeSphere(
        radius: Float,
        color: UIColor,
        collisionRadius: Float? = nil
    ) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        let collisionShape = ShapeResource.generateSphere(radius: collisionRadius ?? radius)
        entity.collision = CollisionComponent(shapes: [collisionShape])

        return entity
    }

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

extension Entity {

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
