/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to indicate that the game is actively being played. This state updates the current time of the level's countdown timer.
*/

import GameplayKit

class LevelSceneActiveState: GKState {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------

    unowned let levelScene: LevelScene
    
    
    // -----------------------------------------------------------------
    // MARK: - Initializers
    // -----------------------------------------------------------------

    init(levelScene: LevelScene) {
        self.levelScene = levelScene
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - GKState Life Cycle
    // -----------------------------------------------------------------
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // Check if the `levelScene` contains any bad `TaskBot`s.
        let allTaskBotsAreGood: Bool = !levelScene.entities.contains(where: {($0 as? TaskBot)?.isGood == false})
       
        // If all the TaskBots are good, the player has completed the level else if there is no time remaining, the player has failed to complete the level.
        if allTaskBotsAreGood {
            stateMachine?.enter(LevelSceneSuccessState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is LevelScenePauseState.Type, is LevelSceneFailState.Type, is LevelSceneSuccessState.Type:
                return true
            default:
                return false
        }
    }
}
