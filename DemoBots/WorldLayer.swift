//
//  WorldLayer.swift
//  DemoBots
//
//  Created by Ross Viviani on 31/08/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import GameplayKit

// The names and z-positions of each layer in a level's world.
enum WorldLayer: CGFloat, CaseIterable {
    
    // The zPosition offset to use per character (`PlayerBot` or `TaskBot`).
    static let zSpacePerCharacter: CGFloat = 100
    
    // Specifying `AboveCharacters` as 1000 gives room for 9 enemies on a level.
    case board = -100
    case debug = -75
    case shadows = -50
    case obstacles = -25
    case characters = 0
    case aboveCharacters = 1000
    case top = 1100
    
    // The expected name for this node in the scene file.
    var nodeName: String {
        switch self {
        case .board:
            return "board"
        case .debug:
            return "debug"
        case .shadows:
            return "shadows"
        case .obstacles:
            return "obstacles"
        case .characters:
            return "characters"
        case .aboveCharacters:
            return "above_characters"
        case .top:
            return "top"
        }
    }
    
    // The full path to this node, for use with `childNode(withName name:)`.
    var nodePath: String {
        return "/world/\(nodeName)"
    }
}
