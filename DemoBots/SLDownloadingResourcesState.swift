/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that the loader is currently downloading on demand resources from the App store.
*/

import GameplayKit

class SceneLoaderDownloadingResourcesState: GKState {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    unowned let sceneLoader: SceneLoader
    
    // Optionally progress directly to preparing state when download completes.
    var enterPreparingStateWhenFinished = false
    
    
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
        self.logCurrentState(state: .downloadingResource, scene: sceneLoader.sceneMetadata.fileName)
      
        // Clear any previous errors, and begin downloading the scene's resources. 
        sceneLoader.error = nil
        
        Task(priority: .background) {
            await beginDownloadingScene()
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is SceneLoaderDownloadFailedState.Type, is SceneLoaderResourcesAvailableState.Type, is SceneLoaderPreparingResourcesState.Type:
                return true
            default:
                return false
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Downloading Actions
    // -----------------------------------------------------------------

    // Downloads the scene into local storage.
    private func beginDownloadingScene() async {
        
        // Create a new bundle request every time downloading needs to begin because `NSBundleResourceRequest`s are single use objects.
        let bundleResourceRequest: NSBundleResourceRequest = NSBundleResourceRequest(tags: sceneLoader.sceneMetadata.onDemandResourcesTags)
        bundleResourceRequest.loadingPriority = 0.8
        
        // Hold onto the new resource request.
        sceneLoader.bundleResourceRequest = bundleResourceRequest
        
        do {
            try await bundleResourceRequest.beginAccessingResources()
            
            // If requested, proceed to the preparing state immediately.
            self.stateMachine!.enter(self.enterPreparingStateWhenFinished ? SceneLoaderPreparingResourcesState.self : SceneLoaderResourcesAvailableState.self)
        } catch {
            
            // Release the resources because we'll need to start a new request.
            bundleResourceRequest.endAccessingResources()
            
            // Set the error on the sceneLoader.
            self.sceneLoader.error = error
            self.stateMachine!.enter(SceneLoaderDownloadFailedState.self)
        }
    }
}
