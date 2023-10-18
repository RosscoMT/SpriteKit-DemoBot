//
//  ControlInputSourceGameStateDelegate.swift
//  DemoBots
//
//  Created by Ross Viviani on 29/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

// Delegate methods for responding to control input that applies to the game as a whole.
protocol ControlInputSourceGameStateDelegate: AnyObject {
    func controlInputSourceDidSelect(_ controlInputSource: ControlInputSourceType)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didSpecifyDirection: ControlInputDirection)
    func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType)
    
#if DEBUG
    func controlInputSourceDidToggleDebugInfo(_ controlInputSource: ControlInputSourceType)
    func controlInputSourceDidTriggerLevelSuccess(_ controlInputSource: ControlInputSourceType)
    func controlInputSourceDidTriggerLevelFailure(_ controlInputSource: ControlInputSourceType)
#endif
}
