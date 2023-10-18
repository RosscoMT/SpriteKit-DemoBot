//
//  ControlInputDirection.swift
//  DemoBots
//
//  Created by Ross Viviani on 29/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import simd
import SpriteKit

enum ControlInputDirection: Int {
    
    case up = 0, down, left, right
    
    init?(vector: SIMD2<Float>) {
        
        // Require sufficient displacement to specify direction.
        guard length(vector) >= 0.5 else {
            return nil
        }
        
        // Take the max displacement as the specified axis.
        if abs(vector.x) > abs(vector.y) {
            self = vector.x > 0 ? .right : .left
        } else {
            self = vector.y > 0 ? .up : .down
        }
    }
    
    func invalidMenuSelection() throws -> SKAction {
        
        // Load correct action for the selected direction, else throw an error
        do {
            switch self {
            case .up:
                return try SKAction.loadAction(name: "InvalidFocusChange_Up")
            case .down:
                return try SKAction.loadAction(name: "InvalidFocusChange_Down")
            case .left:
                return try SKAction.loadAction(name: "InvalidFocusChange_Left")
            case .right:
                return try SKAction.loadAction(name: "InvalidFocusChange_Right")
            }
        } catch {
            throw error
        }
    }
}
