//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation

// MARK: - Protocol
public protocol MKAnalyticsEvent {
    var name: String { get }
    var parameters: [String: Any]? { get }
}

extension MKAnalyticsEvent {
    public func isEqual(to otherEvent: MKAnalyticsEvent) -> Bool {
        return name == otherEvent.name && matchingParameters(parameters, otherEvent.parameters)
    }
    
    private func matchingParameters(_ dict1: [String: Any]?, _ dict2: [String: Any]?) -> Bool {
        // Check if both dictionaries are nil or both are non-nil
        guard let dict1, let dict2 else {
            return dict1 == nil && dict2 == nil
        }

        // compare dicts
        return NSDictionary(dictionary: dict1).isEqual(to: dict2)
    }
}

// MARK: - Default Events

public struct MKAnalyticsGenericEvent: MKAnalyticsEvent {
    public let name: String
    public let parameters: [String : Any]?
    
    public init(
        name: String,
        parameters: [String : Any]? = nil
    ) {
        self.name = name
        self.parameters = parameters
    }
}

public struct MKAdClickEvent: MKAnalyticsEvent {
    public let name: String = "ad_click"
    public let parameters: [String : Any]?
    
    public init(
        campaignId: String,
        parameters: [String : Any]? = nil
    ) {
        var parameters = parameters ?? [:]
        parameters.updateValue(campaignId, forKey: "campaign_id")
        self.parameters = parameters
    }
}

public struct MKAdImpressionEvent: MKAnalyticsEvent {
    public let name: String = "ad_impression"
    public let parameters: [String : Any]?
    
    public init(
        campaignId: String,
        parameters: [String : Any]? = nil
    ) {
        var parameters = parameters ?? [:]
        parameters.updateValue(campaignId, forKey: "campaign_id")
        self.parameters = parameters
    }
}
