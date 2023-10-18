//
//  SceneConfiguration.swift
//  DemoBots (iOS)
//
//  Created by Ross Viviani on 22/08/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

struct SceneConfiguration: Decodable {
    
    enum SceneType: String, Decodable {
        case homeEndScene = "HomeEndScene"
        case levelScene = "LevelScene"
    }
    
    let fileName: String
    let sceneType: SceneType
    let onDemandResourcesTags: [String]?
}
