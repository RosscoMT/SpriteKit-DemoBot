//
//  ChargeBarConfiguration.swift
//  DemoBots
//
//  Created by Ross Viviani on 27/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import SpriteKit

// -----------------------------------------------------------------
// MARK: - Static Properties
// -----------------------------------------------------------------

struct ChargeBarConfiguration {
    
    // The size of the complete bar (back and level indicator).
    static let size: CGSize = CGSize(width: 74.0, height: 10.0)
    
    // The size of the colored level bar.
    static let chargeLevelNodeSize: CGSize = CGSize(width: 70.0, height: 6.0)
    
    // The duration used for actions to update the level indicator.
    static let levelUpdateDuration: TimeInterval = 0.1
    
    // The background color.
    static let backgroundColor: SKColor = SKColor.black
    
    // The charge level node color.
    static let chargeLevelColor: SKColor = SKColor.green
}
