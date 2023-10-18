import SpriteKit

class LoadSceneOperation: NSObject {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // The metadata for the scene to load.
    let sceneMetadata: SceneMetadata
    
    // The scene this operation is responsible for loading. Set after completion.
    var scene: BaseScene?
    
    
    // -----------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------
    
    init(sceneMetadata: SceneMetadata) {
        self.sceneMetadata = sceneMetadata
        super.init()
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - NSOperation
    // -----------------------------------------------------------------
    
    func initalizeScene() throws {
        
        // Load the scene into memory using `SKNode(fileNamed:)
        if let scene: BaseScene = sceneMetadata.sceneType.init(fileNamed: sceneMetadata.fileName) {
            self.scene = scene
            
            // Set up the scene's camera and native size.
            scene.createCamera()
        } else {
            throw GameErrors.sceneFile
        }
    }
}
