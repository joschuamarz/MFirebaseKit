//
//  MKAnalyticsSharedTest.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import XCTest
import FirebaseAnalytics
import MFirebaseKitAnalyticsCore
@testable import MFirebaseKitAnalyticsShared

final class MKAnalyticsSharedTest: XCTestCase {

    func testSharedInstance() {
        XCTAssertTrue(MKAnalytics.shared.instance() is MKSharedAnalytics)
    }
    
    func testLogEvent() {
        let event = MKAnalyticsGenericEvent(name: "testEvent")
        MKAnalytics.shared.instance().log(event)
        XCTAssertTrue(MKAnalytics.shared.instance().contains(event))
    }
}
