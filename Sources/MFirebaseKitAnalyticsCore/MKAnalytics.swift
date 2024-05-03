//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation


public protocol MKAnalytics: NSObject {
    var trackedEvents: [MKAnalyticsEvent] { get set }
    func log(_ event: MKAnalyticsEvent)
}

extension MKAnalytics {
    public func reset() {
        self.trackedEvents.removeAll()
    }
    
    public func contains(_ event: MKAnalyticsEvent) -> Bool {
        return trackedEvents.contains(where: { $0.isEqual(to: event) })
    }
}

