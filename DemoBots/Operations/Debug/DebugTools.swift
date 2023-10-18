//
//  DebugTools.swift
//  DemoBots
//
//  Created by Ross Viviani on 20/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

struct DebugTools {
    
    static func timeStamp() {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ss.SSSS"
        print(dateFormatter.string(from: Date()))
    }
}
