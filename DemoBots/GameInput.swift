/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An abstraction representing game input for the user currently playing the game. Manages the player's control input sources, and handles game controller connections / disconnections.
*/

import GameController

protocol GameInputDelegate: AnyObject {
    // Called whenever a control input source is updated.
    func gameInputDidUpdateControlInputSources(gameInput: GameInput)
}

final class GameInput {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    #if os(tvOS)
    // The control input source that is native to tvOS (gameController). This property is optional to represent that a game controller may not be immediately available upon launch.
    var nativeControlInputSource: ControlInputSourceType?
    #else
    // The control input source that is native to the platform (keyboard or touch).
    let nativeControlInputSource: ControlInputSourceType
    #endif
    
    // An optional secondary input source for a connected game controller.
    private(set) var secondaryControlInputSource: GameControllerInputSource?
    
    var isGameControllerConnected: Bool {
        var isGameControllerConnected: Bool = false
        
        controlsQueue.sync {
            isGameControllerConnected = (self.secondaryControlInputSource != nil) || (self.nativeControlInputSource is GameControllerInputSource)
        }
        
        return isGameControllerConnected
    }

    var controlInputSources: [ControlInputSourceType] {
        
        // Return a non-optional array of `ControlInputSourceType`s.
        let sources: [ControlInputSourceType?] = [nativeControlInputSource, secondaryControlInputSource]
        
        return sources.compactMap {
            return $0 as ControlInputSourceType?
        }
    }

    weak var delegate: GameInputDelegate? {
        didSet {
            // Ensure the delegate is aware of the player's current controls.
            delegate?.gameInputDidUpdateControlInputSources(gameInput: self)
        }
    }
    
    // An internal queue to protect accessing the player's control input sources.
    private let controlsQueue = DispatchQueue(label: "com.example.apple-samplecode.player.controlsqueue")

    
    // -----------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------

    init(nativeControlInputSource: ControlInputSourceType) {
        self.nativeControlInputSource = nativeControlInputSource
        setupGameControllerNotifications()
    }
    
    #if os(tvOS)
    init() {
        
        // Search for paired game controllers.
        for pairedController in GCController.controllers() {
            update(withGameController: pairedController)
        }
        
        registerForGameControllerNotifications()
    }
    #endif

    // Register for `GCGameController` pairing notifications.
    func setupGameControllerNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameInput.handleControllerDidConnectNotification(notification:)),
                                               name: .GCControllerDidConnect,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameInput.handleControllerDidDisconnectNotification(notification:)),
                                               name: .GCControllerDidDisconnect,
                                               object: nil)
    }
    
    func update(withGameController gameController: GCController) {
        controlsQueue.sync {
            #if os(tvOS)
            // Assign a controller to the `nativeControlInputSource` if one does not already exist.
            if self.nativeControlInputSource == nil {
                self.nativeControlInputSource = GameControllerInputSource(gameController: gameController)
                return
            }
            #endif
            
            // If not already assigned, add a game controller as the player's secondary control input source.
            if self.secondaryControlInputSource == nil {
                let gameControllerInputSource: GameControllerInputSource = GameControllerInputSource(gameController: gameController)
                self.secondaryControlInputSource = gameControllerInputSource
                gameController.playerIndex = .index1
            }
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - GCGameController Notification Handling
    // -----------------------------------------------------------------
    
    @objc func handleControllerDidConnectNotification(notification: NSNotification) {
        
        guard let connectedGameController: GCController = notification.object as? GCController else {
            return
        }
        
        update(withGameController: connectedGameController)
        delegate?.gameInputDidUpdateControlInputSources(gameInput: self)
    }
    
    @objc func handleControllerDidDisconnectNotification(notification: NSNotification) {
        
        guard let disconnectedGameController: GCController = notification.object as? GCController else {
            return
        }
        
        // Check if the player was being controlled by the disconnected controller.
        if secondaryControlInputSource?.gameController == disconnectedGameController {
            controlsQueue.sync {
                self.secondaryControlInputSource = nil
            }
            
            // Check for any other connected controllers.
            if let gameController: GCController = GCController.controllers().first {
                update(withGameController: gameController)
            }
            
            delegate?.gameInputDidUpdateControlInputSources(gameInput: self)
        }
    }
}
