/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
*/

import GameplayKit

// A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
class SceneLoader {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    lazy var stateMachine: GKStateMachine = {
        return GKStateMachine(states: GameStateMachine.loaderStates(value: self))
    }()
    
    // The metadata describing the scene whose resources should be loaded.
    let sceneMetadata: SceneMetadata
    
    // The actual scene after it has been successfully loaded. Set in `SceneLoaderPreparingResourcesState`.
    var scene: BaseScene?
    
    var error: Error?
    
    #if os(iOS) || os(tvOS)
    
    // The current `NSBundleResourceRequest` used to download the necessary resources. We keep a reference to the resource request so that it can be modified while it is in progress, and pin the resources when complete. For example: the `loadingPriority` is updated when the user reaches the loading scene, and the request is cancelled and released as part of cleaning up the scene loader.
    var bundleResourceRequest: NSBundleResourceRequest?
    #endif

    // A computed property that returns `true` if the scene's resources are expected to take a long time to load.
    var requiresProgressSceneForPreparing: Bool {
        return sceneMetadata.loadableTypes.contains { $0.resourcesNeedLoading }
    }
    
    // Indicates whether the scene we are loading has been requested to be presented to the user. Used to change how aggressively the resources are being made available.
    var requestedForPresentation = false {
        
        didSet {
             
            // Don't adjust resource loading priorities if `requestedForPresentation` was just set to `false`.
            guard requestedForPresentation else {
                return
            }
            
            #if os(iOS) || os(tvOS)
            // The presentation of this scene is blocked by downloading the scene's resources, so mark the bundle resource request's loading priority as urgent.
            if stateMachine.currentState is SceneLoaderDownloadingResourcesState {
                bundleResourceRequest?.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            }
            #endif
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------
    
    init(sceneMetadata: SceneMetadata) {
        self.sceneMetadata = sceneMetadata
    
        // Enter the initial state as soon as the scene loader is created.
        stateMachine.enter(SceneLoaderInitialState.self)
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Scene operation
    // -----------------------------------------------------------------
    
    func asynchronouslyLoadSceneForPresentation() {
        
        // Ensures that the resources for a scene are downloaded and begins loading them into memory.
        switch stateMachine.currentState {
            case is SceneLoaderResourcesReadyState:
                return
            case is SceneLoaderResourcesAvailableState:
                stateMachine.enter(SceneLoaderPreparingResourcesState.self)
            default:
                #if os(iOS) || os(tvOS)
      
                let downloadingState = stateMachine.state(forClass: SceneLoaderDownloadingResourcesState.self)!
                downloadingState.enterPreparingStateWhenFinished = true
                
                stateMachine.enter(SceneLoaderDownloadingResourcesState.self)
                #elseif os(OSX)
                fatalError("Invalid `currentState`: \(stateMachine.currentState!).")
                #endif
        }
    }
}

#if os(iOS) || os(tvOS)

extension SceneLoader {
    
    
    // -----------------------------------------------------------------
    // MARK: - Scene operation for iOS and tvOS
    // -----------------------------------------------------------------
    
    // Moves the state machine to the appropriate state when a request is made to download the `sceneLoader`'s scene.
    func downloadResourcesIfNecessary() {
        if sceneMetadata.requiresOnDemandResources {
            stateMachine.enter(SceneLoaderDownloadingResourcesState.self)
        } else {
            stateMachine.enter(SceneLoaderResourcesAvailableState.self)
        }
    }
    
    // Marks the resources as no longer necessary cancelling any pending requests.
    func purgeResources() {
        
        // Reset the state machine back to the initial state.
        stateMachine.enter(SceneLoaderInitialState.self)
        
        // Unpin any on demand resources.
        bundleResourceRequest = nil
        
        // Release the loaded scene instance.
        scene = nil
        
        // Discard any errors in preparation for a new loading attempt.
        error = nil
    }
}
#endif

