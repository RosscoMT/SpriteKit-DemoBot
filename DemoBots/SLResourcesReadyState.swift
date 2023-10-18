/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that all of the resources for the scene are loaded into memory and ready for use. This is the final state in the `SceneLoader`'s state machine.
*/

import GameplayKit

class SceneLoaderResourcesReadyState: GKState {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    unowned let sceneLoader: SceneLoader
    
    
    // -----------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------
    
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - GKState Life Cycle
    // -----------------------------------------------------------------
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Log the state
        self.logCurrentState(state: .resourceReady, scene: sceneLoader.sceneMetadata.fileName)

        // Notify to any interested objects that the download has completed.
        NotificationCenter.default.post(name: .sceneLoaderDidCompleteNotification, object: nil, userInfo: ["sceneLoader" : sceneLoader])
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is SceneLoaderResourcesAvailableState.Type, is SceneLoaderInitialState.Type:
                return true
            default:
                return false
        }
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        
        // Presenting the scene is a one shot operation. Clear the scene when  exiting the ready state.
        sceneLoader.scene = nil
    }
}
