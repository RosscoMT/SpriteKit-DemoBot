//
//  GameStateMachine.swift
//  DemoBots
//
//  Created by Ross Viviani on 05/10/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import GameplayKit

struct GameStateMachine {
    
    // Returns all the scene loader states
    static func loaderStates(value: SceneLoader) -> [GKState] {
        var states: [GKState] = [
            SceneLoaderInitialState(sceneLoader: value),
            SceneLoaderResourcesAvailableState(sceneLoader: value),
            SceneLoaderPreparingResourcesState(sceneLoader: value),
            SceneLoaderResourcesReadyState(sceneLoader: value)
        ]
        
        #if os(iOS) || os(tvOS)
        // States associated with on demand resources only apply to iOS and tvOS.
        states += [
            SceneLoaderDownloadingResourcesState(sceneLoader: value),
            SceneLoaderDownloadFailedState(sceneLoader: value)
        ]
        #endif
        
        return states
    }
}
