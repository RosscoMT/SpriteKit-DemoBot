//
//  GameErrors.swift
//  DemoBots
//
//  Created by Ross Viviani on 12/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

enum GameErrors: Error {
    case skActionFailed(String)
    case plistFailedToLoad
    case downloadFailed(String)
    case sceneLoader(String)
    case sceneConfiguration
    case sceneFile
    
    func handle() -> String {
        switch self {
        case .skActionFailed(let string):
            return ""
        case .plistFailedToLoad:
            return ""
        case .downloadFailed(let string):
            return ""
        case .sceneLoader(let string):
            return ""
        case .sceneConfiguration:
            return ""
        case .sceneFile:
            return "Unable to load the SKNode"
        }
    }
}
