//
//  BotConfiguration.swift
//  DemoBots
//
//  Created by Ross Viviani on 07/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

struct BotConfiguration: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case locomotion
        case initialOrientation
        case startsBad
        case goodPathNodeNames
        case badPathNodeNames
    }
    
    let locomotion: LevelConfiguration.TaskBotConfiguration.Locomotion
    let initialOrientation: CompassDirection
    let startsBad: Bool
    let goodPathNodeNames: [String]
    let badPathNodeNames: [String]
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.locomotion = try values.decode(LevelConfiguration.TaskBotConfiguration.Locomotion.self, forKey: .locomotion)
        self.initialOrientation = CompassDirection(string: try values.decode(String.self, forKey: .initialOrientation))
        self.startsBad = try values.decode(Bool.self, forKey: .startsBad)
        self.goodPathNodeNames = try values.decode([String].self, forKey: .goodPathNodeNames)
        self.badPathNodeNames = try values.decode([String].self, forKey: .badPathNodeNames)
    }
}
