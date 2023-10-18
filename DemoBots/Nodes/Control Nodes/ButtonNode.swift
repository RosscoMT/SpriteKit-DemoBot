/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `ButtonNode` is a custom `SKSpriteNode` that provides button-like behavior in a SpriteKit scene. It is supported by `ButtonNodeResponderType` (a protocol for classes that can respond to button presses) and `ButtonIdentifier` (an enumeration that defines all of the kinds of buttons that are supported in the game).
*/

import SpriteKit

// A type that can respond to `ButtonNode` button press events.
protocol ButtonNodeResponderType: AnyObject {
    // Responds to a button press.
    func buttonTriggered(button: ButtonNode)
}

// A custom sprite node that represents a press able and selectable button in a scene.
class ButtonNode: SKSpriteNode {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------

    // The identifier for this button, deduced from its name in the scene.
    var buttonIdentifier: ButtonIdentifier!
    
    /**
        The scene that contains a `ButtonNode` must be a `ButtonNodeResponderType`
        so that touch events can be forwarded along through `buttonPressed()`.
    */
    var responder: ButtonNodeResponderType {
        guard let responder = scene as? ButtonNodeResponderType else {
            fatalError("ButtonNode may only be used within a `ButtonNodeResponderType` scene.")
        }
        return responder
    }

    // Indicates whether the button is currently highlighted (pressed).
    var isHighlighted = false {
        // Animate to a pressed / unpressed state when the highlight state changes.
        didSet {
            // Guard against repeating the same action.
            guard oldValue != isHighlighted else { return }
            
            // Remove any existing animations that may be in progress.
            removeAllActions()
            
            // Create a scale action to make the button look like it is slightly depressed.
            let newScale: CGFloat = isHighlighted ? 0.99 : 1.01
            let scaleAction = SKAction.scale(by: newScale, duration: 0.15)
            
            // Create a color blend action to darken the button slightly when it is depressed.
            let newColorBlendFactor: CGFloat = isHighlighted ? 1.0 : 0.0
            let colorBlendAction = SKAction.colorize(withColorBlendFactor: newColorBlendFactor, duration: 0.15)
            
            // Run the two actions at the same time.
            run(SKAction.group([scaleAction, colorBlendAction]))
        }
    }
    
    // Indicates whether the button is currently selected (on or off). Most buttons do not support or require selection. In DemoBots, selection is used by the screen recorder buttons to indicate whether screen recording is turned on or off. - Change the texture based on the current selection state.
    var isSelected = false {
        didSet {
            texture = isSelected ? selectedTexture : defaultTexture
        }
    }
    
    // The texture to use when the button is not selected.
    var defaultTexture: SKTexture?
    
    // The texture to use when the button is selected.
    var selectedTexture: SKTexture?
    
    // A mapping of neighboring `ButtonNode`s keyed by the `ControlInputDirection` to reach the node.
    var focusableNeighbors = [ControlInputDirection: ButtonNode]()

    // Input focus shows which button will be triggered when the action button is pressed on indirect input devices such as game controllers and keyboards.
    var isFocused = false {
        didSet {
            if isFocused {
                run(SKAction.scale(to: 1.08, duration: 0.20))
                focusRing.alpha = 0.0
                focusRing.isHidden = false
                focusRing.run(SKAction.fadeIn(withDuration: 0.2))
            } else {
                run(SKAction.scale(to: 1.0, duration: 0.20))
                focusRing.isHidden = true
            }
        }
    }
    
    // A node to indicate when a button has the input focus.
    lazy var focusRing: SKNode = {
        
        guard let focusRing: SKNode = self.childNode(withName: .focusRing) else {
            fatalError()
        }
        
        return focusRing
    }()
    
    
    
    // -----------------------------------------------------------------
    // MARK: - Initializers
    // -----------------------------------------------------------------
    
    // Overridden to support `copy(with zone:)`.
    override init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // Ensure that the node has a supported button identifier as its name.
        guard let nodeName = name, let buttonIdentifier = ButtonIdentifier(rawValue: nodeName) else {
            fatalError("Unsupported button name found.")
        }
        
        self.buttonIdentifier = buttonIdentifier

        // Remember the button's default texture (taken from its texture in the scene).
        defaultTexture = texture
        
        // Use a specific selected texture if one is specified for this identifier. // Otherwise, use the default `texture`.
        if let textureName: String = buttonIdentifier.selectedTextureName {
            selectedTexture = SKTexture(imageNamed: textureName)
        } else {
            selectedTexture = texture
        }

        // The focus ring should be hidden until the button is given the input focus.
        focusRing.isHidden = true

        // Enable user interaction on the button node to detect tap and click events.
        isUserInteractionEnabled = true
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Methods
    // -----------------------------------------------------------------
    
    func buttonTriggered() {
        
        // Forward the button press event through to the responder.
        if isUserInteractionEnabled {
            responder.buttonTriggered(button: self)
        }
    }
    
    // Performs an animation to indicate when a user is trying to navigate beyond the available buttons in a requested direction ie a menu.
    func performInvalidFocusChangeAnimationForDirection(direction: ControlInputDirection) {
      
        let animationKey: String = "ButtonNode.InvalidFocusChangeAnimationKey"
        
        guard action(forKey: animationKey) == nil else {
            return
        }
        
        do {
            let theAction: SKAction = try direction.invalidMenuSelection()
            run(theAction, withKey: animationKey)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    

    // -----------------------------------------------------------------
    // MARK: - Touch Responder
    // -----------------------------------------------------------------
    
    #if os(iOS)
    // UIResponder touch handling.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    
        isHighlighted = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    
        isHighlighted = false

        // Touch up inside behavior.
        if containsTouches(touches: touches) {
            buttonTriggered()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
    
        isHighlighted = false
    }
    
    // Determine if any of the touches are within the `ButtonNode`.
    private func containsTouches(touches: Set<UITouch>) -> Bool {
        
        guard let scene: SKScene = scene else {
            fatalError("Button must be used within a scene.")
        }
        
        return touches.contains { touch in
            let touchPoint: CGPoint = touch.location(in: scene)
            let touchedNode: SKNode = scene.atPoint(touchPoint)
            return touchedNode === self || touchedNode.inParentHierarchy(self)
        }
    }
    
    // -----------------------------------------------------------------
    // MARK: - Mouse Responder
    // -----------------------------------------------------------------
    
    #elseif os(OSX)
    // NSResponder mouse handling.
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        isHighlighted = true
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        isHighlighted = false

        // Touch up inside behavior.
        if containsLocationForEvent(event) {
            buttonTriggered()
        }
    }
    
    // Determine if the event location is within the `ButtonNode`.
    private func containsLocationForEvent(_ event: NSEvent) -> Bool {
        
        guard let scene: SKScene = scene else {
            fatalError("Button must be used within a scene.")
        }

        let location: CGPoint = event.location(in: scene)
        let clickedNode: SKNode = scene.atPoint(location)
        return clickedNode === self || clickedNode.inParentHierarchy(self)
    }
    #endif
}

extension ButtonNode {
 
    override func copy(with zone: NSZone? = nil) -> Any {
        
        guard let newButton = super.copy(with: zone) as? ButtonNode else {
            fatalError("Failed to copy")
        }
        
        // Copy the `ButtonNode` specific properties.
        newButton.buttonIdentifier = buttonIdentifier
        newButton.defaultTexture = defaultTexture?.copy() as? SKTexture
        newButton.selectedTexture = selectedTexture?.copy() as? SKTexture
        
        return newButton
    }
}
