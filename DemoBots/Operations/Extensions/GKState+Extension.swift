//
//  GKState+Extension.swift
//  DemoBots
//
//  Created by Ross Viviani on 04/10/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import GameplayKit

extension GKState {
    
    enum State: String {
        case initial
        case downloadingResource
        case downloadFailed
        case resourceAvailable
        case preparingResource
        case resourceReady
    }
    
    func logCurrentState(state: State, scene: String) {
        print("----Entering----\nState: \(state.rawValue.capitalized)State\nScene: \(scene)")
    }
}
