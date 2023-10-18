/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A structure that encapsulates the initial configuration of a level in the game, including the initial states and positions of `TaskBot`s. This information is loaded from a property list.
*/

import Foundation

// Encapsulates the starting configuration of a level in the game.
struct LevelConfiguration {
    
    
    // -----------------------------------------------------------------
    // MARK: - Types
    // -----------------------------------------------------------------

    // Encapsulates the starting configuration of a single `GroundBot` or `FlyingBot`.
    struct TaskBotConfiguration {
        
        
        // -----------------------------------------------------------------
        // MARK: - Properties
        // -----------------------------------------------------------------

        // The different types of `TaskBot` that can exist in a level.
        enum Locomotion: String, Decodable {
            case ground
            case flying
        }
        
        let locomotion: Locomotion
        
        // The initial orientation of this `TaskBot` when the level is first loaded.
        let initialOrientation: CompassDirection
        
        // The names of the nodes for this `TaskBot`'s patrol path when it is "good" and not hunting.
        let goodPathNodeNames: [String]

        // The names of the nodes for this `TaskBot`'s patrol path when it is "bad" and not hunting.
        let badPathNodeNames: [String]
        
        // Whether the bot should be in its "bad" state when the level begins.
        let startsBad: Bool
        
        
        // -----------------------------------------------------------------
        // MARK: - Initialization
        // -----------------------------------------------------------------

        init(botConfigurationInfo: BotConfiguration) {
            locomotion = botConfigurationInfo.locomotion
            initialOrientation = botConfigurationInfo.initialOrientation
            goodPathNodeNames = botConfigurationInfo.goodPathNodeNames
            badPathNodeNames = botConfigurationInfo.badPathNodeNames
            startsBad = botConfigurationInfo.startsBad
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // Cached data loaded from the level's data file.
    private let configurationInfo: ConfigurationInfo
    
    // The initial orientation of the `PlayerBot` when the level is first loaded.
    let initialPlayerBotOrientation: CompassDirection

    // The configuration settings for `TaskBots` on this level.
    let taskBotConfigurations: [TaskBotConfiguration]
    
    // The file name identifier for this level. Used for loading files and assets.
    let fileName: String?
    
    // Returns the name of the next level, if any. The final level doesn't have a next level name, so this property is optional.
    var nextLevelName: String? {
        return configurationInfo.nextLevel
    }
    
    // The time limit (in seconds) for this level.
    var timeLimit: TimeInterval {
        return configurationInfo.timeLimit
    }
    
    // The factor used to normalize distances between characters for 'fuzzy' logic.
    var proximityFactor: Float {
        return configurationInfo.proximityFactor
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Initialization
    // -----------------------------------------------------------------

    init(fileName: String?) throws {
        self.fileName = fileName
        
        guard let url: URL = Bundle.main.url(forResource: fileName, withExtension: "plist") else {
            throw GameErrors.plistFailedToLoad
        }
        
        do {
            
            // Decode the plist data from the URL
            self.configurationInfo = try Data.decodePlistData(url: url)
            
            // Extract the data for every `TaskBot` in this level as an array of `TaskBotConfiguration` values.
            let botConfigurations: [BotConfiguration] = configurationInfo.taskBotConfigurations
            
            // Map the array of `TaskBot` configuration dictionaries to an array of `TaskBotConfiguration` instances.
            self.taskBotConfigurations = botConfigurations.map {
                TaskBotConfiguration(botConfigurationInfo: $0)
            }
            
            self.initialPlayerBotOrientation = configurationInfo.initialPlayerBotOrientation
        } catch {
            throw error
        }
    }
}
