/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The initial state of a `SceneLoader`. Determines which state should be entered at the beginning of the scene loading process.
*/

import GameplayKit

class SceneLoaderInitialState: GKState {
    
    
    
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
        self.logCurrentState(state: .initial, scene: sceneLoader.sceneMetadata.fileName)
        
        #if os(iOS) || os(tvOS)
        self.requiresOnDemandResources()
        #elseif os(OSX)
        // On OS X the resources will always be in local storage available for download.
        stateMachine!.enter(SceneLoaderResourcesAvailableState.self)
        #endif
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        #if os(iOS) || os(tvOS)
        if stateClass is SceneLoaderDownloadingResourcesState.Type {
            return true
        }
        #endif
        
        return stateClass is SceneLoaderResourcesAvailableState.Type
    }
    
    func requiresOnDemandResources() {
        
        // Move the `stateMachine` to the available state if no on-demand resources are required.
        if sceneLoader.sceneMetadata.requiresOnDemandResources == false {
            stateMachine!.enter(SceneLoaderResourcesAvailableState.self)
        }
    }
}
