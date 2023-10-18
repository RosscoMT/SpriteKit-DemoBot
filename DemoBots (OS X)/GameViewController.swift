/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `NSViewController` subclass that stores references to game-wide input sources and managers.
*/

import Cocoa
import SpriteKit

class GameViewController: NSViewController {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // A manager for coordinating scene resources and presentation.
    var sceneManager: SceneManager!
    
    
    // -----------------------------------------------------------------
    // MARK: - View Life Cycle
    // -----------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keyboardControlInputSource = KeyboardControlInputSource()
        let gameInput = GameInput(nativeControlInputSource: keyboardControlInputSource)
        
        do {
            
            // Load the initial home scene.
            guard let skView: SKView = view as? SKView else {
                fatalError("Unable to initialise SKView")
            }
            
            sceneManager = try SceneManager(presentingView: skView, gameInput: gameInput)
        } catch {
            fatalError()
        }
    }
}
