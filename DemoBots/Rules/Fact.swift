//
//  Fact.swift
//  DemoBots
//
//  Created by Ross Viviani on 01/10/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.

//  Abstract:
//  This file introduces the rules used by the `TaskBot` rule system to determine an appropriate action for the `TaskBot`. The rules fall into  three            distinct sets:
//              Percentage of bad `TaskBot`s in the level (low, medium, high):
//                  `BadTaskBotPercentageLowRule`
//                  `BadTaskBotPercentageMediumRule`
//                  `BadTaskBotPercentageHighRule`
//              How close the `TaskBot` is to the `PlayerBot` (near, medium, far):
//                  `PlayerBotNearRule`
//                  `PlayerBotMediumRule`
//                  `PlayerBotFarRule`
//              How close the `TaskBot` is to its nearest "good" `TaskBot` (near, medium, far):
//                  `TaskBotNearRule`
//                  `TaskBotMediumRule`
//                  `TaskBotFarRule`
//

import GameplayKit

enum Fact: String {
    
    // Fuzzy rules pertaining to the proportion of "bad" bots in the level.
    case badTaskBotPercentageLow = "BadTaskBotPercentageLow"
    case badTaskBotPercentageMedium = "BadTaskBotPercentageMedium"
    case badTaskBotPercentageHigh = "BadTaskBotPercentageHigh"
    
    // Fuzzy rules pertaining to this `TaskBot`'s proximity to the `PlayerBot`.
    case playerBotNear = "PlayerBotNear"
    case playerBotMedium = "PlayerBotMedium"
    case playerBotFar = "PlayerBotFar"
    
    // Fuzzy rules pertaining to this `TaskBot`'s proximity to the nearest "good" `TaskBot`.
    case goodTaskBotNear = "GoodTaskBotNear"
    case goodTaskBotMedium = "GoodTaskBotMedium"
    case goodTaskBotFar = "GoodTaskBotFar"
    
    func handle() -> AnyObject {
        return self.rawValue as AnyObject
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Bot Rules
    // -----------------------------------------------------------------
    
    static func huntPlayerBotRules(ruleSystem: GKRuleSystem) -> [Float] {
        
        // A series of situations in which we prefer this `TaskBot` to hunt the player.
        let rules = [
            
            // "Number of bad TaskBots is high" AND "Player is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageHigh.handle(),
                Fact.playerBotNear.handle()
            ]),
            
            // There are already a lot of bad `TaskBot`s on the level, and the player is nearby, so hunt the player.
            // "Number of bad `TaskBot`s is medium" AND "Player is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.handle(),
                Fact.playerBotNear.handle()
            ]),
            
            // There are already a reasonable number of bad `TaskBots` on the level, and the player is nearby, so hunt the player.
            // "Number of bad TaskBots is high" AND "Player is at medium proximity" AND "nearest good `TaskBot` is at medium proximity".
            // There are already a lot of bad `TaskBot`s on the level, so even though both the player and the nearest good TaskBot are at medium proximity, prefer the player for hunting.
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageHigh.handle(),
                Fact.playerBotMedium.handle(),
                Fact.goodTaskBotMedium.handle()
            ])]
        
        return rules
    }
    
    static func huntTaskBotRules(ruleSystem: GKRuleSystem) -> [Float] {
        
        // A series of situations in which we prefer this `TaskBot` to hunt the nearest "good" TaskBot.
        let huntTaskBotRaw: [Float] = [
            
            // "Number of bad TaskBots is low" AND "Nearest good `TaskBot` is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageLow.handle(),
                Fact.goodTaskBotNear.handle()
            ]),
            
            // There are not many bad `TaskBot`s on the level, and a good `TaskBot` is nearby, so hunt the `TaskBot`.
            // "Number of bad TaskBots is medium" AND "Nearest good TaskBot is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.handle(),
                Fact.goodTaskBotNear.handle()
            ]),
            
            // There are a reasonable number of `TaskBot`s on the level, but a good `TaskBot` is nearby, so hunt the `TaskBot`.
            // "Number of bad TaskBots is low" AND "Player is at medium proximity" AND "Nearest good TaskBot is at medium proximity".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageLow.handle(),
                Fact.playerBotMedium.handle(),
                Fact.goodTaskBotMedium.handle()
            ]),
            
            // There are not many bad `TaskBot`s on the level, so even though both the player and the nearest good `TaskBot` are at medium proximity, prefer the nearest good `TaskBot` for hunting.
            
            // "Number of bad `TaskBot`s is medium" AND "Player is far away" AND "Nearest good `TaskBot` is at medium proximity".
            // There are a reasonable number of bad `TaskBot`s on the level, the player is far away, and the nearest good `TaskBot` is at medium proximity, so prefer the nearest good `TaskBot` for hunting.
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.handle(),
                Fact.playerBotFar.handle(),
                Fact.goodTaskBotMedium.handle()
            ]),
        ]
        
        return huntTaskBotRaw
    }
}
