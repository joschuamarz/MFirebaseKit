//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation

public class MKAnalyticsMock: NSObject, MKAnalytics {
    public var trackedEvents: [MKAnalyticsEvent]
    
    public init(trackedEvents: [MKAnalyticsEvent] = []) {
        self.trackedEvents = trackedEvents
    }
    
    public func log(_ event: MKAnalyticsEvent) {
        trackedEvents.append(event)
    }
}
