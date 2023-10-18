//
//  Notifications+Extension.swift
//  DemoBots
//
//  Created by Ross Viviani on 01/09/2022.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

extension Notification.Name {
    public static let sceneLoaderDidCompleteNotification = Notification.Name(rawValue: "SceneLoaderDidCompleteNotification")
    public static let sceneLoaderLoadingInProgress = Notification.Name(rawValue: "SceneLoaderLoadingInProgress")
    public static let sceneLoaderDidFailNotification = Notification.Name(rawValue: "SceneLoaderDidFailNotification")
}
