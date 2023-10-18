/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Protocols that manage and respond to control input for the `PlayerBot` and for the game as a whole.
*/

import simd

// Delegate methods for responding to control input that applies to the `PlayerBot`.
protocol ControlInputSourceDelegate: AnyObject {
    /**
        Update the `ControlInputSourceDelegate` with new displacement
        in a top down 2D coordinate system (x, y):
            Up:    (0.0, 1.0)
            Down:  (0.0, -1.0)
            Left:  (-1.0, 0.0)
            Right: (1.0, 0.0)
    */
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateDisplacement displacement: SIMD2<Float>)
    
    // Update the `ControlInputSourceDelegate` with new angular displacement denoting both the requested angle, and magnitude with which to rotate. Measured in radians.
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateAngularDisplacement angularDisplacement: SIMD2<Float>)
    
    // Update the `ControlInputSourceDelegate` to move forward or backward relative to the orientation of the entity. Forward:  (0.0, 1.0) Backward: (0.0, -1.0)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateWithRelativeDisplacement relativeDisplacement: SIMD2<Float>)
    
    // Update the `ControlInputSourceDelegate` with new angular displacement relative to the entity's existing orientation. Clockwise: (-1.0, 0.0) CounterClockwise: (1.0, 0.0)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateWithRelativeAngularDisplacement relativeAngularDisplacement: SIMD2<Float>)
    
    // Instructs the `ControlInputSourceDelegate` to cause the player to attack.
    func controlInputSourceDidBeginAttacking(_ controlInputSource: ControlInputSourceType)
    
    // Instructs the `ControlInputSourceDelegate` to end the player's attack.
    func controlInputSourceDidFinishAttacking(_ controlInputSource: ControlInputSourceType)
}
