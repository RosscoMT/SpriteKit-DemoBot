/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that supplies and manages the `PlayerBot`'s beam. The beam is used to convert "bad" `TaskBot`s into "good" `TaskBot`s.
*/

import SpriteKit
import GameplayKit

class BeamComponent: GKComponent {

    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------

    // Set to `true` whenever the player is holding down the attack button.
    var isTriggered = false
    
    let beamNode: BeamNode = BeamNode()
    
    var playerBotAntenna: AntennaInfo {
        return AntennaInfo(entity: playerBot, antennaOffset: playerBot.antennaOffset)
    }
    
    // The state machine for this `BeamComponent`. Defined as an implicitly unwrapped optional property, because it is created during initialization, but cannot be created until after we have called super.init().
    lazy var stateMachine: GKStateMachine = {
        return GKStateMachine(states: [
            BeamIdleState(beamComponent: self),
            BeamFiringState(beamComponent: self),
            BeamCoolingState(beamComponent: self)])
    }()

    // The 'PlayerBot' this component is associated with.
    var playerBot: PlayerBot {
        
        guard let playerBot: PlayerBot = entity as? PlayerBot else {
            fatalError("BeamComponents must be associated with a PlayerBot")
        }
        
        return playerBot
    }
    
    // The `RenderComponent' for this component's 'entity'.
    var renderComponent: RenderComponent {
        
        guard let renderComponent: RenderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("A BeamComponent's entity must have a RenderComponent")
        }
        
        return renderComponent
    }

    
    // -----------------------------------------------------------------
    // MARK: - Initializers
    // -----------------------------------------------------------------

    override init() {
        super.init()
        stateMachine.enter(BeamIdleState.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Remove the beam node from the scene.
        beamNode.removeFromParent()
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - GKComponent Life Cycle
    // -----------------------------------------------------------------
    
    override func update(deltaTime seconds: TimeInterval) {
        stateMachine.update(deltaTime: seconds)
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Convenience
    // -----------------------------------------------------------------

    // Finds the nearest "bad" `TaskBot` that lies within the beam's arc. Returns `nil` if no `TaskBot`s are within targeting range.
    func findTargetInBeamArc(withCurrentTarget currentTarget: TaskBot?) -> TaskBot? {
        
        let playerBotNode: SKNode = renderComponent.node
        
        // Use the player's `EntitySnapshot` to build an array of targetable `TaskBot`s who's antennas are within the beam's arc.
        guard let level: LevelScene = playerBotNode.scene as? LevelScene, let snapshot: EntitySnapshot = level.entitySnapshotForEntity(entity: playerBot) else {
            return nil
        }
        
        let botsInArc = snapshot.entityDistances.filter { entityDistance in
            
            guard let taskBot: TaskBot = entityDistance.target as? TaskBot else {
                return false
            }
            
            // Filter out entities that aren't "bad" `TaskBot`s with a `RenderComponent`.
            guard let taskBotNode: SKNode = taskBot.component(ofType: RenderComponent.self)?.node else {
                return false
            }
            
            // Filter out `TaskBot`s that are too far away.
            if taskBot.isGood, entityDistance.distance > Float(GameplayConfiguration.Beam.arcLength) {
                return false
            }
            
            // Filter out any `TaskBot` who's antenna is not within the beam's arc.
            let taskBotAntenna = AntennaInfo(entity: taskBot, antennaOffset: taskBot.beamTargetOffset)
            
            let targetDistanceRatio = entityDistance.distance / Float(GameplayConfiguration.Beam.arcLength)
            
            // Determine the angle between the `playerBotAntenna` and the `taskBotAntenna` adjusting for the distance between the two entities. This adjustment allows for easier aiming as the `PlayerBot` and `TaskBot` get closer together.
            let arcAngle = playerBotAntenna.angleTo(target: taskBotAntenna) * targetDistanceRatio
            
            if arcAngle > Float(GameplayConfiguration.Beam.maxArcAngle) {
                return false
            }

            // Filter out `TaskBot`s where there is scenery between their antenna and the `PlayerBot`'s antenna.
            var hasLineOfSite: Bool = true
            
            level.physicsWorld.enumerateBodies(alongRayStart: playerBotAntenna.position, end: taskBotAntenna.position) { obstacleBody, _, _, stop in
                
                // Ignore nodes that have an entity as they are not scenery.
                if obstacleBody.node?.entity != nil {
                   return
                }
                
                // Calculate the lowest y-position for the obstacle's node.
                guard let obstacleNode: SKNode = obstacleBody.node else {
                    return
                }
                
                let obstacleLowestY: CGFloat = obstacleNode.calculateAccumulatedFrame().origin.y
                
                // If the obstacle's lowest y-position is less than the `TaskBot`'s y-position or the 'PlayerBot'`s y-position, then it blocks the line of sight.
                if obstacleLowestY < taskBotNode.position.y || obstacleLowestY < playerBotNode.position.y {
                    hasLineOfSite = false
                    stop.pointee = true
                }
            }
            
            return hasLineOfSite
        }.map {
            return $0.target as! TaskBot
        }

        let target: TaskBot?
        
        // If the current target is still targetable, continue to target it. Else, return the closest target in the beam's arc.
        if let currentTarget = currentTarget, botsInArc.contains(currentTarget) {
            target = currentTarget
        } else {
            target = botsInArc.first
        }
        
        return target
    }
}
