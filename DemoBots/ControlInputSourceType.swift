//
//  ControlInputSourceType.swift
//  DemoBots
//
//  Created by Ross Viviani on 29/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

// A protocol to be adopted by classes that provide control input and notify their delegates when input is available.
protocol ControlInputSourceType: AnyObject {
    
    // A delegate that receives information about actions that apply to the `PlayerBot`.
    var delegate: ControlInputSourceDelegate? { get set }
    
    // A delegate that receives information about actions that apply to the game as a whole.
    var gameStateDelegate: ControlInputSourceGameStateDelegate? { get set }
    
    var allowsStrafing: Bool { get }
    
    func resetControlState()
}
