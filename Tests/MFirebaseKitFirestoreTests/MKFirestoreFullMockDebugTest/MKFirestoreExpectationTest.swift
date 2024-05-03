//
//  MKFirestoreExpectationTest.swift
//  
//
//  Created by Joschua Marz on 03.05.24.
//

import XCTest
import MFirebaseKitFirestoreCore
@testable import MFirebaseKitFirestoreDebug

final class MKFirestoreExpectationTest: XCTestCase {
    struct BasicQuery: MKFirestoreCollectionQuery {
        struct ResultData: Codable, Identifiable {
            let id: String
        }
            
        typealias BaseResultData = ResultData
        var collectionReference: MKFirestoreCollectionReference = .collection("Test")
        var orderDescriptor: OrderDescriptor? = nil
        var limit: Int? = nil
        var filters: [MKFirestoreQueryFilter] = []
        var mockResultData: [ResultData] = []
    }

    func testInitializer() {
        let referenceQuery = BasicQuery()
        let expectation = MKFirestoreExpectation(
            firestoreReference: referenceQuery.collectionReference,
            type: .query
        )
        XCTAssertEqual(expectation.firestoreReference.rawPath, "Test")
        XCTAssertEqual(expectation.type, .query)
        XCTAssertEqual(expectation.description, "query on Test")
    }
    
    func testIsMatching() {
        let referenceQuery = BasicQuery()
        let expectation = MKFirestoreExpectation(
            firestoreReference: referenceQuery.collectionReference,
            type: .query
        )
        XCTAssertTrue(expectation.isMatching(path: "Test", type: .query))
        XCTAssertFalse(expectation.isMatching(path: "Test2", type: .query))
        XCTAssertFalse(expectation.isMatching(path: "Test/Doc", type: .query))
        XCTAssertFalse(expectation.isMatching(path: "Test", type: .mutation))
        XCTAssertFalse(expectation.isMatching(path: "Test", type: .deletion))
        XCTAssertFalse(expectation.isMatching(path: "Test", type: .listener))
    }

    func testArrayRemoveFirst_noMatch() {
        let referenceQuery = BasicQuery()
        let expectation = MKFirestoreExpectation(
            firestoreReference: referenceQuery.collectionReference,
            type: .query
        )
        var arr = [expectation]
        let element = arr.removeFirst(where: { $0.isMatching(path: "Test2", type: .listener) })
        XCTAssertNil(element)
    }
    
    func testArrayRemoveFirst_match() {
        let referenceQuery = BasicQuery()
        let expectation = MKFirestoreExpectation(
            firestoreReference: referenceQuery.collectionReference,
            type: .query
        )
        var arr = [expectation]
        let element = arr.removeFirst(where: { $0.isMatching(path: "Test", type: .query) })
        XCTAssertEqual(element, expectation)
    }
}
