/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file introduces the rules used by the `TaskBot` rule system to determine an appropriate action for the `TaskBot`. The rules fall into three distinct sets:
                Percentage of bad `TaskBot`s in the level (low, medium, high):
                    `BadTaskBotPercentageLowRule`
                    `BadTaskBotPercentageMediumRule`
                    `BadTaskBotPercentageHighRule`
                How close the `TaskBot` is to the `PlayerBot` (near, medium, far):
                    `PlayerBotNearRule`
                    `PlayerBotMediumRule`
                    `PlayerBotFarRule`
                How close the `TaskBot` is to its nearest "good" `TaskBot` (near, medium, far):
                    `TaskBotNearRule`
                    `TaskBotMediumRule`
                    `TaskBotFarRule`
*/

import GameplayKit


// -----------------------------------------------------------------
// MARK: - TaskBot Rules
// -----------------------------------------------------------------

// Asserts whether the number of "bad" `TaskBot`s is considered "low".
class BadTaskBotPercentageLowRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        return max(0.0, 1.0 - 3.0 * snapshot.badBotPercentage)
    }
    
    init() {
        super.init(fact: .badTaskBotPercentageLow)
    }
}


// Asserts whether the number of "bad" `TaskBot`s is considered "medium".
class BadTaskBotPercentageMediumRule: FuzzyTaskBotRule {
 
    override func grade() -> Float {
        if snapshot.badBotPercentage <= 1.0 / 3.0 {
            return min(1.0, 3.0 * snapshot.badBotPercentage)
        }
        else {
            return max(0.0, 1.0 - (3.0 * snapshot.badBotPercentage - 1.0))
        }
    }
    
    init() {
        super.init(fact: .badTaskBotPercentageMedium)
    }
}


// Asserts whether the number of "bad" `TaskBot`s is considered "high".
class BadTaskBotPercentageHighRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        return min(1.0, max(0.0, (3.0 * snapshot.badBotPercentage - 1)))
    }
    
    init() {
        super.init(fact: .badTaskBotPercentageHigh)
    }
}


// -----------------------------------------------------------------
// MARK: - Player Proximity Rules
// -----------------------------------------------------------------


// Asserts whether the `PlayerBot` is considered to be "near" to this `TaskBot`.
class PlayerBotNearRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }

    init() {
        super.init(fact: .playerBotNear)
    }
}


// Asserts whether the `PlayerBot` is considered to be at a "medium" distance from this `TaskBot`.
class PlayerBotMediumRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (abs(distance - oneThird) / oneThird)
    }
    
    init() {
        super.init(fact: .playerBotMedium)
    }
}


// Asserts whether the `PlayerBot` is considered to be "far" from this `TaskBot`.
class PlayerBotFarRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    init() {
        super.init(fact: .playerBotFar)
    }
}


// -----------------------------------------------------------------
// MARK: - TaskBot Proximity Rules
// -----------------------------------------------------------------


// Asserts whether the nearest "good" `TaskBot` is considered to be "near" to this `TaskBot`.
class GoodTaskBotNearRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodTaskBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }

    init() {
        super.init(fact: .goodTaskBotNear)
    }
}


// Asserts whether the nearest "good" `TaskBot` is considered to be at a "medium" distance from this `TaskBot`.
class GoodTaskBotMediumRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodTaskBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (abs(distance - oneThird) / oneThird)
    }

    init() {
        super.init(fact: .goodTaskBotMedium)
    }
}


// Asserts whether the nearest "good" `TaskBot` is considered to be "far" from this `TaskBot`.
class GoodTaskBotFarRule: FuzzyTaskBotRule {
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodTaskBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    init() {
        super.init(fact: .goodTaskBotFar)
    }
}
