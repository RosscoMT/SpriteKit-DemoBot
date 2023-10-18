/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A floating `TaskBot` with a radius blast attack. This `GKEntity` subclass allows for convenient construction of an entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class FlyingBot: TaskBot, ChargeComponentDelegate, ResourceLoadableType {
    
    
    // -----------------------------------------------------------------
    // MARK: - Static Properties
    // -----------------------------------------------------------------
    
    // The unique attributes of this entity
    static var attribute: EntityAttributes = {
        return .init(textureSize: CGSize(width: 144.0, height: 144.0),
                     shadowSize: CGSize(width: 60.0, height: 27.0),
                     shadowTexture: SKTextureAtlas(named: "Shadows").textureNamed("FlyingBotShadow"),
                     shadowOffset: CGPoint(x: 0.0, y: -58.0))
    }()

    // The animations to use when a `FlyingBot` is in its "good" state.
    static var goodAnimations: [AnimationState: [CompassDirection: Animation]]?

    // The animations to use when a `FlyingBot` is in its "bad" state.
    static var badAnimations: [AnimationState: [CompassDirection: Animation]]?
    
    
    // -----------------------------------------------------------------
    // MARK: - TaskBot Properties
    // -----------------------------------------------------------------

    override var goodAnimations: [AnimationState: [CompassDirection: Animation]] {
        return FlyingBot.goodAnimations!
    }
    
    override var badAnimations: [AnimationState: [CompassDirection: Animation]] {
        return FlyingBot.badAnimations!
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------

    required init(isGood: Bool, goodPathPoints: [CGPoint], badPathPoints: [CGPoint]) {
        super.init(isGood: isGood, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)

        // Determine initial animations and charge based on the initial state of the bot.
        let initialAnimations: [AnimationState: [CompassDirection: Animation]]
        let initialCharge: Double

        if isGood {
            guard let goodAnimations: [AnimationState : [CompassDirection : Animation]] = FlyingBot.goodAnimations else {
                fatalError("Attempt to access FlyingBot.goodAnimations before they have been loaded.")
            }
            
            initialAnimations = goodAnimations
            initialCharge = 0.0
        }
        else {
            guard let badAnimations: [AnimationState : [CompassDirection : Animation]] = FlyingBot.badAnimations else {
                fatalError("Attempt to access FlyingBot.badAnimations before they have been loaded.")
            }
            
            initialAnimations = badAnimations
            initialCharge = GameplayConfiguration.FlyingBot.maximumCharge
        }

        // Create components that define how the entity looks and behaves.
        let renderComponent: RenderComponent = RenderComponent()
        addComponent(renderComponent)

        let orientationComponent: OrientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent: ShadowComponent = ShadowComponent(texture: FlyingBot.attribute.shadowTexture,
                                                               size: FlyingBot.attribute.shadowSize,
                                                               offset: FlyingBot.attribute.shadowOffset)
        addComponent(shadowComponent)

        let animationComponent: AnimationComponent = AnimationComponent(textureSize: FlyingBot.attribute.textureSize,
                                                                        animations: initialAnimations)
        addComponent(animationComponent)

        let intelligenceComponent: IntelligenceComponent = IntelligenceComponent(states: [
            TaskBotAgentControlledState(entity: self),
            FlyingBotPreAttackState(entity: self),
            FlyingBotBlastState(entity: self),
            TaskBotZappedState(entity: self)
        ])
        addComponent(intelligenceComponent)

        let physicsBody: SKPhysicsBody = SKPhysicsBody(circleOfRadius: GameplayConfiguration.TaskBot.physicsBodyRadius, center: GameplayConfiguration.TaskBot.physicsBodyOffset)
        let physicsComponent: PhysicsComponent = PhysicsComponent(physicsBody: physicsBody, colliderType: .TaskBot)
        addComponent(physicsComponent)
        
        let chargeComponent: ChargeComponent = ChargeComponent(charge: initialCharge, maximumCharge: GameplayConfiguration.FlyingBot.maximumCharge)
        chargeComponent.delegate = self
        addComponent(chargeComponent)

        // Connect the `PhysicsComponent` and the `RenderComponent`.
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        // Connect the `RenderComponent` and `ShadowComponent` to the `AnimationComponent`.
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        // Specify the offset for beam targeting.
        beamTargetOffset = GameplayConfiguration.FlyingBot.beamTargetOffset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - ContactableType
    // -----------------------------------------------------------------

    override func contactWithEntityDidBegin(_ entity: GKEntity) {
        super.contactWithEntityDidBegin(entity)
        
        guard !isGood else {
            return
        }

        var shouldStartAttack: Bool = false
        
        if let otherTaskBot: TaskBot = entity as? TaskBot, otherTaskBot.isGood {
            // Contact with good task bot will trigger an attack.
            shouldStartAttack = true
        } else if let playerBot: PlayerBot = entity as? PlayerBot, !playerBot.isPoweredDown {
            // Contact with an active `PlayerBot` will trigger an attack.
            shouldStartAttack = true
        }
        
        if let stateMachine: GKStateMachine = component(ofType: IntelligenceComponent.self)?.stateMachine, shouldStartAttack {
            stateMachine.enter(FlyingBotPreAttackState.self)
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - ChargeComponentDelegate
    // -----------------------------------------------------------------
 
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        
        guard let intelligenceComponent: IntelligenceComponent = component(ofType: IntelligenceComponent.self) else {
            return
        }
        
        intelligenceComponent.stateMachine.enter(TaskBotZappedState.self)
        isGood = !chargeComponent.hasCharge
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - ResourceLoadableType
    // -----------------------------------------------------------------

    static var resourcesNeedLoading: Bool {
        return goodAnimations == nil || badAnimations == nil
    }
    
    static func loadResources() async {
        
        // Load `TaskBot`s shared assets.
        super.loadSharedAssets()
        
        let flyingBotAtlasNames: [String] = ["FlyingBotGoodWalk", "FlyingBotGoodAttack", "FlyingBotBadWalk", "FlyingBotBadAttack", "FlyingBotZapped"]
        
        // Preload all of the texture atlases for `FlyingBot`. This improves the overall loading speed of the animation cycles for this character.
        do {
            let flyingBotAtlases: [SKTextureAtlas] = try await SKTextureAtlas.preloadTextureAtlasesNamed(flyingBotAtlasNames)
            
            // This closure sets up all of the `FlyingBot` animations after the `FlyingBot` texture atlases have finished preloading.
            goodAnimations = [:]
            goodAnimations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: flyingBotAtlases[0], withImageIdentifier: "FlyingBotGoodWalk", forAnimationState: .walkForward, bodyActionName: "FlyingBotBob", shadowActionName: "FlyingBotShadowScale")
            goodAnimations![.attack] = AnimationComponent.animationsFromAtlas(atlas: flyingBotAtlases[1], withImageIdentifier: "FlyingBotGoodAttack", forAnimationState: .attack, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            
            badAnimations = [:]
            badAnimations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: flyingBotAtlases[2], withImageIdentifier: "FlyingBotBadWalk", forAnimationState: .walkForward, bodyActionName: "FlyingBotBob", shadowActionName: "FlyingBotShadowScale")
            badAnimations![.attack] = AnimationComponent.animationsFromAtlas(atlas: flyingBotAtlases[3], withImageIdentifier: "FlyingBotBadAttack", forAnimationState: .attack, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            badAnimations![.zapped] = AnimationComponent.animationsFromAtlas(atlas: flyingBotAtlases[4], withImageIdentifier: "FlyingBotZapped", forAnimationState: .zapped, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
        } catch {
            fatalError("One or more texture atlases could not be found: \(error)")
        }
    }
    
    static func purgeResources() {
        goodAnimations = nil
        badAnimations = nil
    }
}
