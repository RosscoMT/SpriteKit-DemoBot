/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `UIViewController` subclass that stores references to game-wide input sources and managers.
*/

import UIKit
import SpriteKit

class GameViewController: UIViewController, SceneManagerDelegate {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // A placeholder logo view that is displayed before the home scene is loaded.
    @IBOutlet weak var logoView: UIImageView!
    
    // A manager for coordinating scene resources and presentation.
    var sceneManager: SceneManager!
    
    
    // -----------------------------------------------------------------
    // MARK: - View Life Cycle
    // -----------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the `touchControlInputNode` to cover the entire view, and size the controls to a reasonable value.
        let controlLength: CGFloat = min(GameplayConfiguration.TouchControl.minimumControlSize, view.bounds.size.width * GameplayConfiguration.TouchControl.idealRelativeControlSize)
        
        let touchControlInputNode: TouchControlInputNode = TouchControlInputNode(frame: view.bounds,
                                                                                 thumbStickNodeSize: CGSize(width: controlLength, height: controlLength))
        let gameInput: GameInput = GameInput(nativeControlInputSource: touchControlInputNode)
        
        do {
            guard let skView: SKView = view as? SKView else {
                fatalError("Unable to initialise SKView")
            }
            
            sceneManager = try SceneManager(presentingView: skView, gameInput: gameInput)
            sceneManager.delegate = self
        } catch {
            fatalError()
        }
    }
    
    // Hide status bar during game play.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - SceneManagerDelegate
    // -----------------------------------------------------------------
    
    func sceneManager(_ sceneManager: SceneManager, didTransitionTo scene: SKScene) {
        // Fade out the app's initial loading `logoView` if it is visible.
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
            self.logoView.alpha = 0.0
        }, completion: { _ in
            self.logoView.isHidden = true
        })
    }
}
