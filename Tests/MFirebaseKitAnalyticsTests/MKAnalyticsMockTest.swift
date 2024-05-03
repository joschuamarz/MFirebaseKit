//
//  MKAnalyticsMockTest.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import XCTest
@testable import MFirebaseKitAnalyticsCore

final class MKAnalyticsMockTest: XCTestCase {

    let analytics = MKAnalyticsMock()
    
    override func setUp() {
        analytics.reset()
    }
    
    func testAdClickTracking() {
        analytics.log(MKAdClickEvent(campaignId: "some-test-campaign"))
        let expectedEvent = MKAnalyticsGenericEvent(
            name: "ad_click",
            parameters: ["campaign_id": "some-test-campaign"]
        )
        XCTAssertTrue(analytics.contains(expectedEvent))
    }
    
    func testAdImpressionTracking() {
        analytics.log(MKAdImpressionEvent(campaignId: "some-test-campaign"))
        let expectedEvent = MKAnalyticsGenericEvent(
            name: "ad_impression",
            parameters: ["campaign_id": "some-test-campaign"]
        )
        XCTAssertTrue(analytics.contains(expectedEvent))
    }
    
    func testGenericEventWithParameters() {
        let event = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: [
                "number": 1,
                "text": "test",
                "dict": ["some": "test"],
                "bool": true
            ]
        )
        let unExpectedEvent_differentName = MKAnalyticsGenericEvent(
            name: "test-event_different",
            parameters: [
                "number": 1,
                "text": "test",
                "dict": ["some": "test"],
                "bool": true
            ]
        )
        let unExpectedEvent_differentNumber = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: [
                "number": 2,
                "text": "test",
                "dict": ["some": "test"],
                "bool": true
            ]
        )
        let unExpectedEvent_differentText = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: [
                "number": 1,
                "text": "test2",
                "dict": ["some": "test"],
                "bool": true
            ]
        )
        let unExpectedEvent_differentDict = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: [
                "number": 1,
                "text": "test",
                "dict": ["some": "test-other"],
                "bool": true
            ]
        )
        let unExpectedEvent_differentBool = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: [
                "number": 1,
                "text": "test",
                "dict": ["some": "test"],
                "bool": false
            ]
        )
        let unExpectedEvent_noParams = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: nil
        )
        
        analytics.log(event)
        XCTAssertTrue(analytics.contains(event))
        // Verify that differences are handled correctly
        XCTAssertFalse(analytics.contains(unExpectedEvent_differentName))
        XCTAssertFalse(analytics.contains(unExpectedEvent_differentNumber))
        XCTAssertFalse(analytics.contains(unExpectedEvent_differentText))
        XCTAssertFalse(analytics.contains(unExpectedEvent_differentDict))
        XCTAssertFalse(analytics.contains(unExpectedEvent_differentBool))
        XCTAssertFalse(analytics.contains(unExpectedEvent_noParams))
    }
    
    func testGenericEventWithoutParameters() {
        let event = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: nil
        )
        let unExpectedEvent_withParams = MKAnalyticsGenericEvent(
            name: "test-event",
            parameters: [
                "number": 1,
                "text": "test",
                "dict": ["some": "test"],
                "bool": true
            ]
        )
        
        analytics.log(event)
        XCTAssertTrue(analytics.contains(event))
        // Verify that differences are handled correctly
        XCTAssertFalse(analytics.contains(unExpectedEvent_withParams))
    }

}
