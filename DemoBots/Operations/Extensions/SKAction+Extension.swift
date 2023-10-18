//
//  SKAction+Extension.swift
//  DemoBots
//
//  Created by Ross Viviani on 24/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import SpriteKit

extension SKAction {
    
    // Safely attempt to load an action else throw an error
    static func loadAction(name: String) throws -> SKAction {
        if let action: SKAction = SKAction(named: name) {
            return action
        }
        
        throw GameErrors.skActionFailed(name)
    }
}
