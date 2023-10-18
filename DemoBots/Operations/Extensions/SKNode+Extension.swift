//
//  SKNode+Extension.swift
//  DemoBots
//
//  Created by Ross Viviani on 19/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import SpriteKit

extension SKNode {
    
    enum Nodes: String {
        
        // Progress scene
        case backgroundNode
        case label
        case progressBar
        
        // Level scene
        case world
        case transporter = "transporter_coordinate"
        
        // Level scen overlay state
        case levelPreview
        
        // Scene overlay
        case overlay = "Overlay"
        
        // Beam node
        case beamLine = "BeamLine"
        
        // Button node
        case focusRing
        
        func handle() -> String {
            return self.rawValue
        }
    }
    
    convenience init?(asset: GameResources) {
        self.init(fileNamed: asset.rawValue)
    }
    
    func childNode(withName node: Nodes) -> SKNode? {
        return childNode(withName: node.handle())
    }
    
}
