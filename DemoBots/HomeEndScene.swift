/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `SKScene` used to represent and manage the home and end scenes of the game.
*/

import SpriteKit

class HomeEndScene: BaseScene {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------

    // Returns the background node from the scene.
    override var backgroundNode: SKSpriteNode? {
        return childNode(withName: .backgroundNode) as? SKSpriteNode
    }
    
    // The screen recorder button for the scene (if it has one).
    var screenRecorderButton: ButtonNode? {
        return backgroundNode?.childNode(withName: ButtonIdentifier.screenRecorderToggle.identifer) as? ButtonNode
    }
    
    // The "NEW GAME" button which allows the player to proceed to the first level.
    var proceedButton: ButtonNode? {
        return backgroundNode?.childNode(withName: ButtonIdentifier.proceedToNextScene.identifer) as? ButtonNode
    }

    
    // -----------------------------------------------------------------
    // MARK: - Scene Life Cycle
    // -----------------------------------------------------------------

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        #if os(iOS)
        screenRecorderButton?.isSelected = screenRecordingToggleEnabled
        #else
        screenRecorderButton?.isHidden = true
        #endif
        
        // Enable focus based navigation. 
        focusChangesEnabled = true
        
        // Setup notifications
        setupNotifications()
        centerCameraOnPoint(point: backgroundNode!.position)
        
        // Begin loading the first level as soon as the view appears.
        sceneManager.prepareScene(identifier: .level(1))
        
        let levelLoader: SceneLoader = sceneManager.sceneLoader(forSceneIdentifier: .level(1))
        
        // If the first level is not ready, hide the buttons until we are notified.
        if (levelLoader.stateMachine.currentState is SceneLoaderResourcesReadyState) == false {
            proceedButton?.alpha = 0.0
            proceedButton?.isUserInteractionEnabled = false
            
            screenRecorderButton?.alpha = 0.0
            screenRecorderButton?.isUserInteractionEnabled = false
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Scene Life Cycle
    // -----------------------------------------------------------------
    
    func setupNotifications() {
        
        // Register for scene loader notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(SceneLoaderUpdate(notification:)),
                                               name: .sceneLoaderDidCompleteNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SceneLoaderUpdate(notification:)),
                                               name: .sceneLoaderDidFailNotification,
                                               object: nil)
    }
    
    @objc func SceneLoaderUpdate(notification: Notification) {
        
        // Use userInfo for offloading loader
        guard let sceneLoader: SceneLoader = notification.userInfo?["sceneLoader"] as? SceneLoader else {
            return
        }
        
        // Show the proceed button if the `sceneLoader` pertains to a `LevelScene`.
        if sceneLoader.sceneMetadata.sceneType is LevelScene.Type {
            
            // Allow the proceed and screen to be tapped or clicked.
            self.proceedButton?.isUserInteractionEnabled = true
            self.screenRecorderButton?.isUserInteractionEnabled = true
            
            // Fade in the proceed and screen recorder buttons.
            self.screenRecorderButton?.run(SKAction.fadeIn(withDuration: 1.0))
            
            // Clear the initial `proceedButton` focus.
            self.proceedButton?.isFocused = false
            
            // Indicate that the `proceedButton` is focused.
            self.proceedButton?.run(SKAction.fadeIn(withDuration: 0.5)) {
                self.resetFocus()
            }
        }
    }
}
