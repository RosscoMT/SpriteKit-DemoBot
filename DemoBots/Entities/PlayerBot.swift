/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKEntity` subclass that represents the player-controlled protagonist of DemoBots. This subclass allows for convenient construction of a new entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class PlayerBot: GKEntity, ChargeComponentDelegate, ResourceLoadableType {
    
    // -----------------------------------------------------------------
    // MARK: - Static Properties
    // -----------------------------------------------------------------
    
    // The unique attributes of this entity
    static var attribute: EntityAttributes = {
        return .init(textureSize: CGSize(width: 120.0, height: 120.0),
                     shadowSize: CGSize(width: 90.0, height: 40.0),
                     shadowTexture: SKTextureAtlas(named: "Shadows").textureNamed("PlayerBotShadow"),
                     shadowOffset: CGPoint(x: 0.0, y: -40.0))
    }()
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    var isPoweredDown = false
    
    // The agent used when pathfinding to the `PlayerBot`.
    let agent: GKAgent2D

    // A `PlayerBot` is only targetable when it is actively being controlled by a player or is taking damage. It is not targetable when appearing or recharging.
    var isTargetable: Bool {
        
        guard let currentState: GKState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState else {
            return false
        }

        switch currentState {
            case is PlayerBotPlayerControlledState, is PlayerBotHitState:
                return true
            default:
                return false
        }
    }
    
    // Used to determine the location on the `PlayerBot` where the beam starts.
    var antennaOffset = GameplayConfiguration.PlayerBot.antennaOffset
    
    // The `RenderComponent` associated with this `PlayerBot`.
    var renderComponent: RenderComponent {
        
        guard let renderComponent: RenderComponent = component(ofType: RenderComponent.self) else {
            fatalError("A PlayerBot must have an RenderComponent.")
        }
        
        return renderComponent
    }

    
    // -----------------------------------------------------------------
    // MARK: - Initializers
    // -----------------------------------------------------------------

    override init() {
        agent = GKAgent2D()
        agent.radius = GameplayConfiguration.PlayerBot.agentRadius
        
        super.init()
        
        // Add the `RenderComponent` before creating the `IntelligenceComponent` states, so that they have the render node available to them when first entered (e.g. so that `PlayerBotAppearState` can add a shader to the render node).
        let renderComponent: RenderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent: OrientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent: ShadowComponent = ShadowComponent(texture: PlayerBot.attribute.shadowTexture,
                                                               size: PlayerBot.attribute.shadowSize,
                                                               offset: PlayerBot.attribute.shadowOffset)
        addComponent(shadowComponent)
        
        let inputComponent: InputComponent = InputComponent()
        addComponent(inputComponent)

        // `PhysicsComponent` provides the `PlayerBot`'s physics body and collision masks.
        let physicsComponent: PhysicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius:GameplayConfiguration.PlayerBot.physicsBodyRadius,
                                                                                             center: GameplayConfiguration.PlayerBot.physicsBodyOffset),
                                                                  colliderType: .PlayerBot)
        addComponent(physicsComponent)

        // Connect the `PhysicsComponent` and the `RenderComponent`.
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        // `MovementComponent` manages the movement of a `PhysicalEntity` in 2D space, and chooses appropriate movement animations.
        let movementComponent: MovementComponent = MovementComponent()
        addComponent(movementComponent)
        
        // `ChargeComponent` manages the `PlayerBot`'s charge (i.e. health).
        let chargeComponent: ChargeComponent = ChargeComponent(charge: GameplayConfiguration.PlayerBot.initialCharge,
                                                               maximumCharge: GameplayConfiguration.PlayerBot.maximumCharge,
                                                               displaysChargeBar: true)
        chargeComponent.delegate = self
        addComponent(chargeComponent)
        
        // `AnimationComponent` tracks and vends the animations for different entity states and directions.
        guard let animations: [AnimationState: [CompassDirection: Animation]] = PlayerBot.attribute.animations else {
            fatalError("Attempt to access PlayerBot.animations before they have been loaded.")
        }
        
        let animationComponent: AnimationComponent = AnimationComponent(textureSize: PlayerBot.attribute.textureSize,
                                                                        animations: animations)
        addComponent(animationComponent)
        
        // Connect the `RenderComponent` and `ShadowComponent` to the `AnimationComponent`.
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        // `BeamComponent` implements the beam that a `PlayerBot` fires at "bad" `TaskBot`s.
        let beamComponent: BeamComponent = BeamComponent()
        addComponent(beamComponent)
        
        let intelligenceComponent: IntelligenceComponent = IntelligenceComponent(states: [
            PlayerBotAppearState(entity: self),
            PlayerBotPlayerControlledState(entity: self),
            PlayerBotHitState(entity: self),
            PlayerBotRechargingState(entity: self)
        ])
        addComponent(intelligenceComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Charge component delegate
    // -----------------------------------------------------------------
    
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        if let intelligenceComponent: IntelligenceComponent = component(ofType: IntelligenceComponent.self) {
            if !chargeComponent.hasCharge {
                isPoweredDown = true
                intelligenceComponent.stateMachine.enter(PlayerBotRechargingState.self)
            } else {
                intelligenceComponent.stateMachine.enter(PlayerBotHitState.self)
            }
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - ResourceLoadableType
    // -----------------------------------------------------------------

    static var resourcesNeedLoading: Bool {
        return PlayerBot.attribute.appearTextures == nil || PlayerBot.attribute.animations == nil
    }
    
    static func loadResources() async {
        
        PlayerBot.attribute.teleportShader = SKShader(fileNamed: "Teleport.fsh")
        PlayerBot.attribute.teleportShader?.addUniform(SKUniform(name: "u_duration",
                                                                 float: Float(GameplayConfiguration.PlayerBot.appearDuration)))
        
        ColliderType.definedCollisions[.PlayerBot] = [
            .PlayerBot,
            .TaskBot,
            .Obstacle
        ]
        
        let playerBotAtlasNames: [String] = ["PlayerBotIdle", "PlayerBotWalk", "PlayerBotInactive", "PlayerBotHit"]
        
        // Preload all of the texture atlases for `PlayerBot`. This improves the overall loading speed of the animation cycles for this character.
        do {
            let playerBotAtlases: [SKTextureAtlas] = try await SKTextureAtlas.preloadTextureAtlasesNamed(playerBotAtlasNames)
            
            // This closure sets up all of the `PlayerBot` animations after the `PlayerBot` texture atlases have finished preloading. Store the first texture from each direction of the `PlayerBot`'s idle animation, for use in the `PlayerBot`'s "appear"  state.
            PlayerBot.attribute.appearTextures = [:]
            
            for orientation in CompassDirection.allCases {
                PlayerBot.attribute.appearTextures![orientation] = AnimationComponent.firstTextureForOrientation(compassDirection: orientation,
                                                                                                                 inAtlas: playerBotAtlases[0],
                                                                                                                 withImageIdentifier: "PlayerBotIdle")
            }
            
            // Set up all of the `PlayerBot`s animations.
            PlayerBot.attribute.animations = [:]
            
            PlayerBot.attribute.animations![.idle] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[0],
                                                                                            withImageIdentifier: "PlayerBotIdle",
                                                                                            forAnimationState: .idle)
            
            PlayerBot.attribute.animations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1],
                                                                                                   withImageIdentifier: "PlayerBotWalk",
                                                                                                   forAnimationState: .walkForward)
            
            PlayerBot.attribute.animations![.walkBackward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1],
                                                                                                    withImageIdentifier: "PlayerBotWalk",
                                                                                                    forAnimationState: .walkBackward,
                                                                                                    playBackwards: true)
            
            PlayerBot.attribute.animations![.inactive] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[2],
                                                                                                withImageIdentifier: "PlayerBotInactive",
                                                                                                forAnimationState: .inactive)
            
            PlayerBot.attribute.animations![.hit] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[3],
                                                                                           withImageIdentifier: "PlayerBotHit",
                                                                                           forAnimationState: .hit,
                                                                                           repeatTexturesForever: false)
        } catch {
            fatalError("One or more texture atlases could not be found: \(error)")
        }
    }
    
    static func purgeResources() {
        PlayerBot.attribute.appearTextures = nil
        PlayerBot.attribute.animations = nil
    }

    
    // -----------------------------------------------------------------
    // MARK: - Convenience
    // -----------------------------------------------------------------

    // Sets the `PlayerBot` `GKAgent` position to match the node position (plus an offset).
    func updateAgentPositionToMatchNodePosition() {
        
        // `renderComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let renderComponent: RenderComponent = self.renderComponent
        
        let agentOffset: CGPoint = GameplayConfiguration.PlayerBot.agentOffset
        agent.position = SIMD2<Float>(x: Float(renderComponent.node.position.x + agentOffset.x), y: Float(renderComponent.node.position.y + agentOffset.y))
    }
}
