/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `LevelScene` is an `SKScene` representing a playable level in the game. `WorldLayer` is an enumeration that represents the different z-indexed layers of a `LevelScene`.
*/

import GameplayKit

class LevelScene: BaseScene, SKPhysicsContactDelegate {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // Stores a reference to the root nodes for each world layer in the scene.
    var worldLayerNodes: [WorldLayer: SKNode] = [WorldLayer: SKNode]()
    
    var worldNode: SKNode {
        
        guard let worldNode: SKNode = childNode(withName: .world) else {
            fatalError()
        }
        
        return worldNode
    }

    let playerBot: PlayerBot = PlayerBot()
    var entities: Set<GKEntity> = Set<GKEntity>()
    
    var lastUpdateTimeInterval: TimeInterval = 0
    let maximumUpdateDeltaTime: TimeInterval = 1.0 / 60.0
    
    var levelConfiguration: LevelConfiguration!
    
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
        LevelSceneActiveState(levelScene: self),
        LevelScenePauseState(levelScene: self),
        LevelSceneSuccessState(levelScene: self),
        LevelSceneFailState(levelScene: self)
    ])
 
    override var overlay: SceneOverlay? {
        didSet {
            // Ensure that focus changes are only enabled when the `overlay` is present.
            focusChangesEnabled = (overlay != nil)
        }
    }
  
    
    // -----------------------------------------------------------------
    // MARK: - Pathfinding
    // -----------------------------------------------------------------

    let graph: GKObstacleGraph = GKObstacleGraph(obstacles: [], bufferRadius: GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius)
  
    lazy var obstacleSpriteNodes: [SKSpriteNode] = self["world/obstacles/*"] as! [SKSpriteNode]
    lazy var polygonObstacles: [GKPolygonObstacle] = SKNode.obstacles(fromNodePhysicsBodies: self.obstacleSpriteNodes)
  
    
    // -----------------------------------------------------------------
    // MARK: - Pathfinding Debug
    // -----------------------------------------------------------------
    
    var debugDrawingEnabled = false {
        didSet {
            debugDrawingEnabledDidChange()
        }
    }
    var graphLayer: SKNode = SKNode()
    var debugObstacleLayer: SKNode = SKNode()
    
    
    // -----------------------------------------------------------------
    // MARK: - Rule State
    // -----------------------------------------------------------------
    
    var levelStateSnapshot: LevelStateSnapshot?
    
    func entitySnapshotForEntity(entity: GKEntity) -> EntitySnapshot? {
        
        // Create a snapshot of the level's state if one does not already exist for this update cycle.
        if levelStateSnapshot == nil {
            levelStateSnapshot = LevelStateSnapshot(scene: self)
        }
        
        // Find and return the entity snapshot for this entity.
        return levelStateSnapshot!.entitySnapshots[entity]
    }

    
    // -----------------------------------------------------------------
    // MARK: - Component Systems
    // -----------------------------------------------------------------
    
    lazy var componentSystems: [GKComponentSystem] = {
        let agentSystem = GKComponentSystem(componentClass: TaskBotAgent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let chargeSystem = GKComponentSystem(componentClass: ChargeComponent.self)
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let beamSystem = GKComponentSystem(componentClass: BeamComponent.self)
        let rulesSystem = GKComponentSystem(componentClass: RulesComponent.self)
        
        // The systems will be updated in order. This order is explicitly defined to match assumptions made within components.
        return [rulesSystem, intelligenceSystem, movementSystem, agentSystem, chargeSystem, beamSystem, animationSystem]
    }()
    

    // -----------------------------------------------------------------
    // MARK: - Scene Life Cycle
    // -----------------------------------------------------------------
  
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        do {
            // Load the level's configuration from the level data file.
            levelConfiguration = try LevelConfiguration(fileName: sceneManager.currentSceneMetadata?.fileName)
            
            // Set up the path finding graph with all polygon obstacles.
            graph.addObstacles(polygonObstacles)
            
            // Register for notifications about the app becoming inactive.
            registerForPauseNotifications()
            
            // Create references to the base nodes that define the different layers of the scene.
            loadWorldLayers()
            
            // Add a `PlayerBot` for the player.
            beamInPlayerBot()
            
            // Gravity will be in the negative z direction; there is no x or y component.
            physicsWorld.gravity = .zero
            
            // The scene will handle physics contacts itself.
            physicsWorld.contactDelegate = self
            
            // Move to the active state, starting the level timer.
            stateMachine.enter(LevelSceneActiveState.self)
            
            // Add the debug layers to the scene.
            addNode(node: graphLayer, toWorldLayer: .debug)
            addNode(node: debugObstacleLayer, toWorldLayer: .debug)
            
            // A convenience function to find node locations given a set of node names.
            func nodePointsFromNodeNames(nodeNames: [String]) -> [CGPoint] {
                
                guard let charactersNode: SKNode = childNode(withName: WorldLayer.characters.nodePath) else {
                    return []
                }
                
                return nodeNames.map { charactersNode[$0].first!.position }
            }
            
            // Iterate over the `TaskBot` configurations for this level, and create each `TaskBot`.
            for taskBotConfiguration in levelConfiguration.taskBotConfigurations {
                let taskBot: TaskBot
                
                // Find the locations of the nodes that define the `TaskBot`'s "good" and "bad" patrol paths.
                let goodPathPoints: [CGPoint] = nodePointsFromNodeNames(nodeNames: taskBotConfiguration.goodPathNodeNames)
                let badPathPoints: [CGPoint] = nodePointsFromNodeNames(nodeNames: taskBotConfiguration.badPathNodeNames)
                
                // Create the appropriate type `TaskBot` (ground or flying).
                switch taskBotConfiguration.locomotion {
                case .flying:
                    taskBot = FlyingBot(isGood: !taskBotConfiguration.startsBad, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
                case .ground:
                    taskBot = GroundBot(isGood: !taskBotConfiguration.startsBad, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
                }
                
                // Set the `TaskBot`'s initial orientation so that it is facing the correct way.
                guard let orientationComponent: OrientationComponent = taskBot.component(ofType: OrientationComponent.self) else {
                    fatalError("A task bot must have an orientation component to be able to be added to a level")
                }
                
                orientationComponent.compassDirection = taskBotConfiguration.initialOrientation
                
                // Set the `TaskBot`'s initial position.
                let taskBotNode: SKNode = taskBot.renderComponent.node
                taskBotNode.position = taskBot.isGood ? goodPathPoints.first! : badPathPoints.first!
                taskBot.updateAgentPositionToMatchNodePosition()
                
                // Add the `TaskBot` to the scene and the component systems.
                addEntity(entity: taskBot)
                
                // Add the `TaskBot`'s debug drawing node beneath all characters.
                addNode(node: taskBot.debugNode, toWorldLayer: .debug)
            }
            
            #if os(iOS)
            // Set up iOS touch controls. The player's `nativeControlInputSource` is added to the scene by the `BaseSceneTouchEventForwarding` extension.
            addTouchInputToScene()
            touchControlInputNode.hideThumbStickNodes = sceneManager.gameInput.isGameControllerConnected
            
            // Start screen recording. See `LevelScene+ScreenRecording` for implementation.
            startScreenRecording()
            #endif
        } catch {
            fatalError()
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        // A `LevelScene` needs to update its camera constraints to match the new aspect ratio of the window when the window size changes.
        setCameraConstraints()
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - SKScene Processing
    // -----------------------------------------------------------------
    
    // Called before each frame is rendered.
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Don't perform any updates if the scene isn't in a view.
        guard view != nil else {
            return
        }
        
        // Calculate the amount of time since `update` was last called.
        var deltaTime: TimeInterval = currentTime - lastUpdateTimeInterval
        
        // If more than `maximumUpdateDeltaTime` has passed, clamp to the maximum; otherwise use `deltaTime`.
        deltaTime = deltaTime > maximumUpdateDeltaTime ? maximumUpdateDeltaTime : deltaTime
        
        // The current time will be used as the last update time in the next execution of the method.
        lastUpdateTimeInterval = currentTime
        
        // Get rid of the now-stale `LevelStateSnapshot` if it exists. It will be regenerated when next needed.
        levelStateSnapshot = nil
        
        // Don't evaluate any updates if the `worldNode` is paused. Pausing a subsection of the node tree allows the `camera` and `overlay` nodes to remain interactive.
        if worldNode.isPaused {
            return
        }
        
        // Update the level's state machine.
        stateMachine.update(deltaTime: deltaTime)

        // Update each component system. The order of systems in `componentSystems` is important and was determined when the `componentSystems` array was instantiated.
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    override func didFinishUpdate() {
        
        // Check if the `playerBot` has been added to this scene.
        if let playerBotNode: SKNode = playerBot.component(ofType: RenderComponent.self)?.node, playerBotNode.scene == self {
            
            // Update the `PlayerBot`'s agent position to match its node position. This makes sure that the agent is in a valid location in the SpriteKit physics world at the start of its next update cycle.
            playerBot.updateAgentPositionToMatchNodePosition()
        }
        
        // Sort the entities in the scene by ascending y-position.
        let ySortedEntities: [GKEntity] = entities.sorted { itemOne, ItemTwo in
    
            let nodeA: SKNode = itemOne.component(ofType: RenderComponent.self)!.node
            let nodeB: SKNode = ItemTwo.component(ofType: RenderComponent.self)!.node
            
            return nodeA.position.y > nodeB.position.y
        }
        
        // Set the `zPosition` of each entity so that entities with a higher y-position are rendered above those with a lower y-position.
        var characterZPosition: CGFloat = WorldLayer.zSpacePerCharacter
        
        for entity in ySortedEntities {
            
            guard let node: SKNode = entity.component(ofType: RenderComponent.self)?.node else {
                continue
            }
            
            node.zPosition = characterZPosition
            
            // Use a large enough z-position increment to leave space for emitter effects.
            characterZPosition += WorldLayer.zSpacePerCharacter
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - SKPhysicsContactDelegate
    // -----------------------------------------------------------------
    
    @objc(didBeginContact:) func didBegin(_ contact: SKPhysicsContact) {
        handleContact(contact: contact) { (ContactNotifiableType: ContactNotifiableType, otherEntity: GKEntity) in
            ContactNotifiableType.contactWithEntityDidBegin(otherEntity)
        }
    }
    
    @objc(didEndContact:) func didEnd(_ contact: SKPhysicsContact) {
        handleContact(contact: contact) { (ContactNotifiableType: ContactNotifiableType, otherEntity: GKEntity) in
            ContactNotifiableType.contactWithEntityDidEnd(otherEntity)
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - SKPhysicsContactDelegate convenience
    // -----------------------------------------------------------------
  
    private func handleContact(contact: SKPhysicsContact, contactCallback: (ContactNotifiableType, GKEntity) -> Void) {
        
        // Get the `ColliderType` for each contacted body.
        let colliderTypeA: ColliderType = ColliderType(rawValue: contact.bodyA.categoryBitMask)
        let colliderTypeB: ColliderType = ColliderType(rawValue: contact.bodyB.categoryBitMask)
        
        // Determine which `ColliderType` should be notified of the contact.
        let aWantsCallback: Bool = colliderTypeA.notifyOnContactWith(colliderTypeB)
        let bWantsCallback: Bool = colliderTypeB.notifyOnContactWith(colliderTypeA)
        
        // Make sure that at least one of the entities wants to handle this contact.
        assert(aWantsCallback || bWantsCallback, "Unhandled physics contact - A = \(colliderTypeA), B = \(colliderTypeB)")
        
        let entityA: GKEntity? = contact.bodyA.node?.entity
        let entityB: GKEntity? = contact.bodyB.node?.entity

        /*
            If `entityA` is a notifiable type and `colliderTypeA` specifies that it should be notified
            of contact with `colliderTypeB`, call the callback on `entityA`.
        */
        if let notifiableEntity: ContactNotifiableType = entityA as? ContactNotifiableType, let otherEntity: GKEntity = entityB, aWantsCallback {
            contactCallback(notifiableEntity, otherEntity)
        }
        
        /*
            If `entityB` is a notifiable type and `colliderTypeB` specifies that it should be notified
            of contact with `colliderTypeA`, call the callback on `entityB`.
        */
        if let notifiableEntity: ContactNotifiableType = entityB as? ContactNotifiableType, let otherEntity: GKEntity = entityA, bWantsCallback {
            contactCallback(notifiableEntity, otherEntity)
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Level Construction
    // -----------------------------------------------------------------
    
    func loadWorldLayers() {
        
        for worldLayer in WorldLayer.allCases {
            
            // Try to find a matching node for this world layer's node name.
            let foundNodes: [SKNode] = self["world/\(worldLayer.nodeName)"]
            
            // Make sure it was possible to find a node with this name.
            precondition(!foundNodes.isEmpty, "Could not find a world layer node for \(worldLayer.nodeName)")
            
            // Retrieve the actual node.
            guard let layerNode: SKNode = foundNodes.first else {
                return
            }
            
            // Make sure that the node's `zPosition` is correct relative to the other world layers.
            layerNode.zPosition = worldLayer.rawValue
            
            // Store a reference to the retrieved node.
            worldLayerNodes[worldLayer] = layerNode
        }
    }
    
    func addEntity(entity: GKEntity) {
        
        entities.insert(entity)

        for componentSystem in self.componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }

        // If the entity has a `RenderComponent`, add its node to the scene.
        if let renderNode: SKNode = entity.component(ofType: RenderComponent.self)?.node {
            
            addNode(node: renderNode, toWorldLayer: .characters)

            // If the entity has a `ShadowComponent`, add its shadow node to the scene. Constrain the `ShadowComponent`'s node to the `RenderComponent`'s node.
            if let shadowNode: SKNode = entity.component(ofType: ShadowComponent.self)?.node {
                addNode(node: shadowNode, toWorldLayer: .shadows)
                
                // Constrain the shadow node's position to the render node.
                let xRange: SKRange = SKRange(constantValue: shadowNode.position.x)
                let yRange: SKRange = SKRange(constantValue: shadowNode.position.y)

                let constraint: SKConstraint = SKConstraint.positionX(xRange, y: yRange)
                constraint.referenceNode = renderNode
                shadowNode.constraints = [constraint]
            }
            
            // If the entity has a `ChargeComponent` with a `ChargeBar`, add the `ChargeBar` to the scene. Constrain the `ChargeBar` to the `RenderComponent`'s node.
            if let chargeBar: ChargeBar = entity.component(ofType: ChargeComponent.self)?.chargeBar {
                addNode(node: chargeBar, toWorldLayer: .aboveCharacters)
                
                // Constrain the `ChargeBar`'s node position to the render node.
                let constraint: SKConstraint = SKConstraint.positionX(SKRange(constantValue: GameplayConfiguration.PlayerBot.chargeBarOffset.x),
                                                                      y: SKRange(constantValue: GameplayConfiguration.PlayerBot.chargeBarOffset.y))
                constraint.referenceNode = renderNode
                chargeBar.constraints = [constraint]
            }
        }
        
        // If the entity has an `IntelligenceComponent`, enter its initial state.
        if let intelligenceComponent: IntelligenceComponent = entity.component(ofType: IntelligenceComponent.self) {
            intelligenceComponent.enterInitialState()
        }
    }
    
    func addNode(node: SKNode, toWorldLayer worldLayer: WorldLayer) {
        
        guard let worldLayerNode: SKNode = worldLayerNodes[worldLayer] else {
            return
        }
        
        worldLayerNode.addChild(node)
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - GameInputDelegate
    // -----------------------------------------------------------------

    override func gameInputDidUpdateControlInputSources(gameInput: GameInput) {
        super.gameInputDidUpdateControlInputSources(gameInput: gameInput)
        
        // Update the player's `controlInputSources` to delegate input to the playerBot's `InputComponent`.
        for controlInputSource in gameInput.controlInputSources {
            controlInputSource.delegate = playerBot.component(ofType: InputComponent.self)
        }
        
        #if os(iOS)
        // When a game controller is connected, hide the thumb stick nodes.
        touchControlInputNode.hideThumbStickNodes = gameInput.isGameControllerConnected
        #endif
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - ControlInputSourceGameStateDelegate
    // -----------------------------------------------------------------
    
    override func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType) {
        
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelScenePauseState.self)
        } else {
            stateMachine.enter(LevelSceneActiveState.self)
        }
    }
    
    #if DEBUG
    override func controlInputSourceDidToggleDebugInfo(_ controlInputSource: ControlInputSourceType) {
        debugDrawingEnabled = !debugDrawingEnabled
        
        if let view: SKView = view {
            view.showsPhysics   = debugDrawingEnabled
            view.showsFPS       = debugDrawingEnabled
            view.showsNodeCount = debugDrawingEnabled
            view.showsDrawCount = debugDrawingEnabled
        }
    }
    
    override func controlInputSourceDidTriggerLevelSuccess(_ controlInputSource: ControlInputSourceType) {
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelSceneSuccessState.self)
        }
    }
    
    override func controlInputSourceDidTriggerLevelFailure(_ controlInputSource: ControlInputSourceType) {
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelSceneFailState.self)
        }
    }

    #endif
    
    
    // -----------------------------------------------------------------
    // MARK: - ButtonNodeResponderType
    // -----------------------------------------------------------------
    
    override func buttonTriggered(button: ButtonNode) {
        
        guard let buttonIdentifier: ButtonIdentifier = button.buttonIdentifier else {
            return
        }
        
        switch buttonIdentifier {
        case .resume:
            stateMachine.enter(LevelSceneActiveState.self)
        default:
            // Allow `BaseScene` to handle the event in `BaseScene+Buttons`.
            super.buttonTriggered(button: button)
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Convenience
    // -----------------------------------------------------------------
    
    // Constrains the camera to follow the PlayerBot without approaching the scene edges.
    private func setCameraConstraints() {
        
        // Don't try to set up camera constraints if we don't yet have a camera.
        guard let camera: SKCameraNode = camera else {
            return
        }
        
        // Constrain the camera to stay a constant distance of 0 points from the player node.
        let zeroRange: SKRange = SKRange(constantValue: 0.0)
        let playerNode: SKNode = playerBot.renderComponent.node
        let playerBotLocationConstraint: SKConstraint = SKConstraint.distance(zeroRange, to: playerNode)
        
        /*
            Also constrain the camera to avoid it moving to the very edges of the scene.
            First, work out the scaled size of the scene. Its scaled height will always be
            the original height of the scene, but its scaled width will vary based on
            the window's current aspect ratio.
        */
        let scaledSize: CGSize = CGSize(width: size.width * camera.xScale, height: size.height * camera.yScale)

        // Find the root "board" node in the scene (the container node for the level's background tiles).
        let boardNode: SKNode = childNode(withName: WorldLayer.board.nodePath)!
        
        /*
            Calculate the accumulated frame of this node.
            The accumulated frame of a node is the outer bounds of all of the node's
            child nodes, i.e. the total size of the entire contents of the node.
            This gives us the bounding rectangle for the level's environment.
        */
        let boardContentRect: CGRect = boardNode.calculateAccumulatedFrame()

        /*
            Work out how far within this rectangle to constrain the camera.
            We want to stop the camera when we get within 100pts of the edge of the screen,
            unless the level is so small that this inset would be outside of the level.
        */
        let xInset: CGFloat = min((scaledSize.width / 2) - 100.0, boardContentRect.width / 2)
        let yInset: CGFloat = min((scaledSize.height / 2) - 100.0, boardContentRect.height / 2)
        
        // Use these insets to create a smaller inset rectangle within which the camera must stay.
        let insetContentRect: CGRect = boardContentRect.insetBy(dx: xInset, dy: yInset)
        
        // Define an `SKRange` for each of the x and y axes to stay within the inset rectangle.
        let xRange: SKRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange: SKRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        
        // Constrain the camera within the inset rectangle.
        let levelEdgeConstraint: SKConstraint = SKConstraint.positionX(xRange, y: yRange)
        levelEdgeConstraint.referenceNode = boardNode
        
        // Add both constraints to the camera. The scene edge constraint is added second, so that it takes precedence over following the `PlayerBot`. The result is that the camera will follow the player, unless this would mean moving too close to the edge of the level.
        camera.constraints = [playerBotLocationConstraint, levelEdgeConstraint]
    }
    
    private func beamInPlayerBot() {
        
        // Find the location of the player's initial position.
        guard let charactersNode: SKNode = childNode(withName: WorldLayer.characters.nodePath), let transporterCoordinate: SKNode = charactersNode.childNode(withName: .transporter) else {
            return
        }
        
        // Set the initial orientation.
        guard let orientationComponent: OrientationComponent = playerBot.component(ofType: OrientationComponent.self) else {
            fatalError("A player bot must have an orientation component to be able to be added to a level")
        }
        
        orientationComponent.compassDirection = levelConfiguration.initialPlayerBotOrientation

        // Set up the `PlayerBot` position in the scene.
        let playerNode: SKNode = playerBot.renderComponent.node
        playerNode.position = transporterCoordinate.position
        playerBot.updateAgentPositionToMatchNodePosition()
        
        // Constrain the camera to the `PlayerBot` position and the level edges.
        setCameraConstraints()
        
        // Add the `PlayerBot` to the scene and component systems.
        addEntity(entity: playerBot)
    }
}
