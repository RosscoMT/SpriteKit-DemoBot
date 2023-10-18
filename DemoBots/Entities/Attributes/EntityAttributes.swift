//
//  EntityAttributes.swift
//  DemoBots
//
//  Created by Ross Viviani on 27/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import SpriteKit

struct EntityAttributes {
    
    // The size to use for the entities animation textures.
    var textureSize: CGSize
    
    // The size to use for the entities shadow texture.
    var shadowSize: CGSize
    
    // The actual texture to use for the entities shadow.
    var shadowTexture: SKTexture
    
    // The offset of the entities shadow from its center position.
    var shadowOffset: CGPoint
    
    // The animations to use for a entities
    var animations: [AnimationState: [CompassDirection: Animation]]?
    
    // Textures used by entities appearState to show during appearing in the scene.
    var appearTextures: [CompassDirection: SKTexture]?
    
    // Provides a "teleport" effect shader for when the entities first appears on a level.
    var teleportShader: SKShader?
}
