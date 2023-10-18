/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A subclass of `NSOperation` that maps the different states of an `NSOperation`
        to an explicit `state` enum.
*/

import Foundation

class SceneOperation: Operation {


    // -----------------------------------------------------------------
    // MARK: - Types
    // -----------------------------------------------------------------

    // Using the `@objc` prefix exposes this enum to the ObjC runtime, allowing the use of `dynamic` on the `state` property.
    @objc enum State: Int {
        case ready
        case executing
        case finished
        case cancelled
    }


    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------

    // Marking `state` as dynamic allows this property to be key-value observed.
    dynamic var state: State = .ready


    // -----------------------------------------------------------------
    // MARK: - NSOperation
    // -----------------------------------------------------------------

    override var isExecuting: Bool {
        return state == .executing
    }

    override var isFinished: Bool {
        return state == .finished
    }

    override var isCancelled: Bool {
        return state == .cancelled
    }

    /**
        Add the "state" key to the key value observable properties of `NSOperation`.
    */
    class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }

    class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }

    class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }

    class func keyPathsForValuesAffectingIsCancelled() -> Set<String> {
        return ["state"]
    }
}
