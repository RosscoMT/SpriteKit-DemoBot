/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A subclass of `Operation` that manages the loading of a `ResourceLoadableType`'s resources.
            
*/

import Foundation

class LoadResourcesOperation: NSObject {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // A class that conforms to the `ResourceLoadableType` protocol.
    let loadableType: ResourceLoadableType.Type
   
    
    // ------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------
    
    init(loadableType: ResourceLoadableType.Type) {
        self.loadableType = loadableType
        super.init()
    }
    
    func start() async {
   
        // Avoid reloading the resources if they are already available.
        guard loadableType.resourcesNeedLoading else {
            return
        }

        await loadableType.loadResources()
    }
}
