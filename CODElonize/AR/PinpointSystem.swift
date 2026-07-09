
import RealityKit
import UIKit
import os

class PinpointSystem {

    private(set) var pinpoints: [Entity] = []

    private let areaColors: [UIColor] = [
        .systemRed,       
        .systemPurple,    
        .systemGreen,     
        .systemBlue,      
        .systemOrange,    
        .systemYellow,    
    ]

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

    func areaIndex(for entity: Entity) -> Int? {
        return entity.findPinpointAreaIndex()
    }

    func updatePinpointAppearance(areaIndex: Int, ownerColor: UIColor?) {
        guard areaIndex < pinpoints.count else { return }

        let pinpoint = pinpoints[areaIndex]

        if let sphere = pinpoint.children.first as? ModelEntity {
            let color = ownerColor ?? areaColors[areaIndex]
            sphere.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
        }
    }

    func removeAllPinpoints() {
        for pinpoint in pinpoints {
            pinpoint.removeFromParent()
        }
        pinpoints.removeAll()
        AppLogger.ar.debug("All pinpoints removed")
    }
}
