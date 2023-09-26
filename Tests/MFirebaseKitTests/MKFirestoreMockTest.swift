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
        var response: MKFirestoreQueryResponse<TestDocumentQuery>?
        firestore.executeQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: query.mockResultData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.responseData?.name, query.mockResultData.name)
    }
    
    func testUnauthenticatedDocumentQuery() {
        let firestore = FirestoreMock()
        let query = TestDocumentQuery()
        var response: MKFirestoreQueryResponse<TestDocumentQuery>?
        firestore.executeQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
    }
    
    func testCollectionQuery() {
        let firestore = FirestoreMock()
        let query = TestCollectionQuery()
        var response: MKFirestoreQueryResponse<TestCollectionQuery>?
        firestore.executeQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: query.mockResultData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.responseData?.count, query.mockResultData.count)
    }
    
    func testUnauthenticatedCollectionQuery() {
        let firestore = FirestoreMock()
        let query = TestCollectionQuery()
        var response: MKFirestoreQueryResponse<TestCollectionQuery>?
        firestore.executeQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
        
    }
    
     /*
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
     */
    // MARK: - Helper
    
    struct TestDocumentQuery: MKFirestoreQuery {
        var firestorePath: MKFirestorePath = .collectionPath("Collection1/Document1")
        
        var mockResultData: TestQueryResultDataType = .init(name: "Test")
        
        typealias ResultData = TestQueryResultDataType
    }
    
    struct TestCollectionQuery: MKFirestoreQuery {
        typealias ResultData = [TestQueryResultDataType]
        
        var firestorePath: MKFirestorePath = .collectionPath("Collection1/Document1/Collection2")
        
        var mockResultData: [TestQueryResultDataType] = [
            .init(name: "A"),
            .init(name: "B"),
            .init(name: "C"),
        ]
    }
    
    struct TestQueryResultDataType: Codable {
        let name: String
    }
    
    
}
