//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation
import FirebaseAnalytics
import MFirebaseKitAnalyticsCore

extension MKAnalytics {
    typealias shared = MKSharedAnalytics
}

public class MKSharedAnalytics: NSObject, MKAnalytics {
    private static var sharedInstance: MKSharedAnalytics?
    public static func instance() -> MKAnalytics {
        if let sharedInstance {
            return sharedInstance
        } else {
            let instance = MKSharedAnalytics()
            sharedInstance = instance
            return instance
        }
    }
    
    public var trackedEvents: [MKAnalyticsEvent] = []
    
    public func log(_ event: MKAnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
        trackedEvents.append(event)
    }
}
