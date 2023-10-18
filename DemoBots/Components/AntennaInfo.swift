//
//  AntennaInfo.swift
//  DemoBots
//
//  Created by Ross Viviani on 27/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

struct AntennaInfo {
    
    // The position of the antenna.
    let position: CGPoint
    
    // The direction the antenna is facing.
    let rotation: Float
    
    init(entity: GKEntity, antennaOffset: CGPoint) {
        
        guard let renderComponent: RenderComponent = entity.component(ofType: RenderComponent.self) else {
            fatalError("An AntennaInfo must be created with an entity that has a RenderComponent")
        }
        
        guard let orientationComponent: OrientationComponent = entity.component(ofType: OrientationComponent.self) else {
            fatalError("An AntennaInfo must be created with an entity that has an OrientationComponent")
        }
        
        position = CGPoint(x: renderComponent.node.position.x + antennaOffset.x, y: renderComponent.node.position.y + antennaOffset.y)
        rotation = Float(orientationComponent.zRotation)
    }
    
    func angleTo(target: AntennaInfo) -> Float {
        
        // Create a vector that represents the translation to the target position.
        let translationVector: SIMD2<Float> = SIMD2<Float>(x: Float(target.position.x - position.x), y: Float(target.position.y - position.y))
        
        // Create a unit vector that represents the rotation.
        let angleVector: SIMD2<Float> = SIMD2<Float>(x: cos(rotation), y: sin(rotation))
        
        // Calculate the dot product.
        let dotProduct: Float = dot(translationVector, angleVector)
        
        // Use the dot product and magnitude of the translation vector to determine the angle to the target.
        let translationVectorMagnitude = hypot(translationVector.x, translationVector.y)
        let angle = acos(dotProduct / translationVectorMagnitude)
        
        return angle
    }
}
