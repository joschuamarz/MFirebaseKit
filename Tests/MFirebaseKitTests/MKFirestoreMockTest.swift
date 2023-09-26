//
//  MKFirestoreMockTest.swift
//  
//
//  Created by Joschua Marz on 24.09.23.
//

import XCTest
@testable import MFirebaseKit

final class MKFirestoreMockTest: XCTestCase {
    
    func testDocumentQuery() {
        let firestore = FirestoreMock()
        let query = TestDocumentQuery()
        var response: MKDocumentQueryResponse<TestDocumentQuery>?
        firestore.executeDocumentQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: query.mockResult)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.responseData?.name, query.mockResult.name)
    }
    
    func testUnauthenticatedDocumentQuery() {
        let firestore = FirestoreMock()
        let query = TestDocumentQuery()
        var response: MKDocumentQueryResponse<TestDocumentQuery>?
        firestore.executeDocumentQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
        XCTAssertEqual(response?.error?.code, .unauthenticated)
    }
    
    func testCollectionQuery() {
        let firestore = FirestoreMock()
        let query = TestCollectionQuery()
        var response: MKCollectionQueryResponse<TestCollectionQuery>?
        firestore.executeCollectionQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: query.mockResult)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.responseData?.count, query.mockResult.count)
    }
    
    func testUnauthenticatedCollectionQuery() {
        let firestore = FirestoreMock()
        let query = TestCollectionQuery()
        var response: MKCollectionQueryResponse<TestCollectionQuery>?
        firestore.executeCollectionQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
        XCTAssertEqual(response?.error?.code, .unauthenticated)
    }
    
    // MARK: - Async
    func testAsyncDocumentQuery() {
        let firestore = FirestoreMock()
        let query = TestDocumentQuery()
        let dataExpectation = XCTestExpectation(description: "Data arrived")
        Task {
            let response = await firestore.executeDocumentQuery(query)
            if response.responseData != nil {
                dataExpectation.fulfill()
            }
        }
        sleep(1)
        firestore.respond(to: query, with: query.mockResult)
        wait(for: [dataExpectation], timeout: 2)
    }
    
    func testAsyncUnauthenticatedDocumentQuery() {
        let firestore = FirestoreMock()
        let query = TestDocumentQuery()
        let errorExpectation = XCTestExpectation(description: "Unauthenticated error occured")
        Task {
            let response = await firestore.executeDocumentQuery(query)
            if response.error?.code == .unauthenticated {
                errorExpectation.fulfill()
            }
        }
        sleep(1)
        firestore.respond(to: query, with: .unauthenticated)
        wait(for: [errorExpectation], timeout: 2)
    }
    
    func testAsyncCollectionQuery() {
        let firestore = FirestoreMock()
        let query = TestCollectionQuery()
        let dataExpectation = XCTestExpectation(description: "Data arrived")
        Task {
            let response = await firestore.executeCollectionQuery(query)
            if response.responseData != nil {
                dataExpectation.fulfill()
            }
        }
        sleep(1)
        firestore.respond(to: query, with: query.mockResult)
        wait(for: [dataExpectation], timeout: 2)
    }
    
    func testAsyncUnauthenticatedCollectionQuery() {
        let firestore = FirestoreMock()
        let query = TestCollectionQuery()
        let errorExpectation = XCTestExpectation(description: "Unauthenticated error occured")
        Task {
            let response = await firestore.executeCollectionQuery(query)
            if response.error?.code == .unauthenticated {
                errorExpectation.fulfill()
            }
        }
        sleep(1)
        firestore.respond(to: query, with: .unauthenticated)
        wait(for: [errorExpectation], timeout: 2)
    }
}

// MARK: - Helper

struct TestDocumentQuery: MKDocumentQuery {
    typealias ResultData = ResultType
    
    var document: MKFirestoreDocument = MKFirestoreCollection("Collection1").document("Document1").collection("Collection2").document("Document2")
    
    var mockResult: ResultType = .init(name: "test")
    
    struct ResultType: Codable {
        let name: String
    }
}

struct TestCollectionQuery: MKCollectionQuery {
    typealias ResultData = Data
    
    let collection: MKFirestoreCollection = MKFirestoreCollection("Collection1").document("Document1").collection("Collection2")
    
    let mockResult: [ResultData] = [
        .init(name: "1"),
        .init(name: "2"),
        .init(name: "3"),
    ]
    
    struct Data: Codable {
        let name: String
    }
}
