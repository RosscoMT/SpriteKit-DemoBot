//
//  ButtonIdentifier.swift
//  DemoBots
//
//  Created by Ross Viviani on 10/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

// The complete set of button identifiers supported in the app.
enum ButtonIdentifier: String, CaseIterable {
    case resume = "Resume"
    case home = "Home"
    case proceedToNextScene = "ProceedToNextScene"
    case replay = "Replay"
    case retry = "Retry"
    case cancel = "Cancel"
    case screenRecorderToggle = "ScreenRecorderToggle"
    case viewRecordedContent = "ViewRecordedContent"
    
    // The name of the texture to use for a button when the button is selected.
    var selectedTextureName: String? {
        switch self {
        case .screenRecorderToggle:
            return "ButtonAutoRecordOn"
        default:
            return nil
        }
    }
    
    var identifer: String {
        return self.rawValue
    }
    
    static func focusPriority() -> [ButtonIdentifier] {
        return [
            .resume,
            .proceedToNextScene,
            .replay,
            .retry,
            .home,
            .cancel,
            .viewRecordedContent,
            .screenRecorderToggle
        ]
    }
}
