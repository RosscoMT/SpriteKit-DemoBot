//
//  ConfigurationInfo.swift
//  DemoBots
//
//  Created by Ross Viviani on 07/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

struct ConfigurationInfo: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case nextLevel
        case timeLimit
        case initialPlayerBotOrientation
        case proximityFactor
        case taskBotConfigurations
    }
    
    let nextLevel: String?
    let timeLimit: TimeInterval
    let initialPlayerBotOrientation: CompassDirection
    let proximityFactor: Float
    let taskBotConfigurations: [BotConfiguration]
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.nextLevel = try values.decodeIfPresent(String.self, forKey: .nextLevel)
        self.timeLimit = try values.decode(Double.self, forKey: .timeLimit)
        self.initialPlayerBotOrientation = CompassDirection(string: try values.decode(String.self, forKey: .initialPlayerBotOrientation))
        self.proximityFactor = try values.decode(Float.self, forKey: .proximityFactor)
        self.taskBotConfigurations = try values.decode([BotConfiguration].self, forKey: .taskBotConfigurations)
    }
}
