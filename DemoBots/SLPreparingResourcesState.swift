/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that resources for the scene are being loaded into memory.
*/

import GameplayKit

class SceneLoaderPreparingResourcesState: GKState {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    unowned let sceneLoader: SceneLoader
    
//    // An internal operation queue for loading scene resources in the background.
//    let operationQueue: OperationQueue = OperationQueue()
//    let dispatchQueue: DispatchQueue = DispatchQueue(label: "sceneloaderpreparingresourcesstate", qos: .utility)

    
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
        self.logCurrentState(state: .preparingResource, scene: sceneLoader.sceneMetadata.fileName)
         
        // Begin loading the scene and associated resources in the background.
        Task(priority: .userInitiated) {
            let loadSceneOperation: LoadSceneOperation = await loadResourcesAsynchronously()
            loadSceneProcess(loadScene: loadSceneOperation)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            
            // Only valid if the `sceneLoader`'s scene has been loaded.
            case is SceneLoaderResourcesReadyState.Type where sceneLoader.scene != nil:
                return true
            case is SceneLoaderResourcesAvailableState.Type:
                return true
            default:
                return false
        }
    }
    
    
    
    // -----------------------------------------------------------------
    // MARK: - Load Resources
    // -----------------------------------------------------------------
    
    private func loadSceneProcess(loadScene: LoadSceneOperation) {
         
        do {
            try loadScene.initalizeScene()
            self.sceneLoader.scene = loadScene.scene
            let didEnterReadyState: Bool = self.stateMachine!.enter(SceneLoaderResourcesReadyState.self)
            assert(didEnterReadyState, "Failed to transition to `ReadyState` after resources were prepared.")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func loadResourcesAsynchronously() async -> LoadSceneOperation {
        
        let sceneMetadata: SceneMetadata = sceneLoader.sceneMetadata
        let loadSceneOperation: LoadSceneOperation = LoadSceneOperation(sceneMetadata: sceneMetadata)
        
        guard sceneMetadata.loadableTypes.isEmpty == false else {
            return loadSceneOperation
        }
        
        let resources: [LoadResourcesOperation] = sceneMetadata.loadableTypes.compactMap({LoadResourcesOperation(loadableType: $0)})
        
        var index: Int = 0
        
        // For loops don't work well with async await
        while index < resources.count {
            let initialResources: LoadResourcesOperation = resources[index]
            await initialResources.start()
            index += 1
        }
        
        return loadSceneOperation
    }
}
