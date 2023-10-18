/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `BaseScene` to enable it to respond to button presses.
*/

import Foundation

// Extends `BaseScene` to respond to ButtonNode events.
extension BaseScene {
    
    // Searches the scene for all `ButtonNode`s.
    func findAllButtonsInScene() -> [ButtonNode] {
        return ButtonIdentifier.allCases.compactMap { buttonIdentifier in
            childNode(withName: "//\(buttonIdentifier.rawValue)") as? ButtonNode
        }
    }
}
