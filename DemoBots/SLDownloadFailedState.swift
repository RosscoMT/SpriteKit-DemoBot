/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that the downloading of on demand resources failed.
*/

import GameplayKit

class SceneLoaderDownloadFailedState: GKState {
    
    
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
        self.logCurrentState(state: .downloadFailed, scene: sceneLoader.sceneMetadata.fileName)
        
        // Notify any interested objects that the download has failed.
        NotificationCenter.default.post(name: .sceneLoaderDidFailNotification, object: sceneLoader)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SceneLoaderDownloadingResourcesState.Type
    }
}
