/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `SKSpriteNode` subclass that displays a `PlayerBot`'s remaining charge.
*/

import SpriteKit

class ChargeBar: SKSpriteNode {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    var level: Double = 1.0 {
        didSet {
            
            // Scale the level bar node based on the current health level.
            let action: SKAction = SKAction.scaleX(to: CGFloat(level),
                                                   duration: ChargeBarConfiguration.levelUpdateDuration)
            action.timingMode = .easeInEaseOut
            chargeLevelNode.run(action)
        }
    }
    
    // A node representing the charge level.
    let chargeLevelNode: SKSpriteNode = SKSpriteNode(color: ChargeBarConfiguration.chargeLevelColor,
                                                     size: ChargeBarConfiguration.chargeLevelNodeSize)
    
    
    
    // -----------------------------------------------------------------
    // MARK: - Initializers
    // -----------------------------------------------------------------
    
    init() {
        super.init(texture: nil, color: ChargeBarConfiguration.backgroundColor, size: ChargeBarConfiguration.size)
        
        addChild(chargeLevelNode)
        
        // Constrain the position of the `chargeLevelNode`.
        let xRange: SKRange = SKRange(constantValue: chargeLevelNode.size.width / -2.0)
        let yRange: SKRange = SKRange(constantValue: 0.0)
        
        let constraint: SKConstraint = SKConstraint.positionX(xRange, y: yRange)
        constraint.referenceNode = self
        
        chargeLevelNode.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        chargeLevelNode.constraints = [constraint]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
