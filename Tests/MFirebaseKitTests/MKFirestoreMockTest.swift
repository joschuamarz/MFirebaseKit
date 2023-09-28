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
        let firestore = MKFirestoreMock()
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
        let firestore = MKFirestoreMock()
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
        let firestore = MKFirestoreMock()
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
        let firestore = MKFirestoreMock()
        let query = TestCollectionQuery()
        var response: MKFirestoreQueryResponse<TestCollectionQuery>?
        firestore.executeQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
        
    }
    
    func testDocumentPermutationAutoError() {
        let firestore = MKFirestoreMock(autoResponse: .error(.firestoreError(.init(.aborted))))
        let permutation = TestDocumentPermutation()
        var response: MKFirestorePermutationResponse?
        firestore.executePermutation(permutation) { newResponse in
            response = newResponse
        }
        
        XCTAssertNil(response?.documentId)
        XCTAssertNotNil(response?.error)
    }
    
    // MARK: - Helper
    
    struct TestDocumentQuery: MKFirestoreQuery {
        var firestoreReference: MKFirestoreReference = .collection("Collection1").document("doc")
        
        var mockResultData: TestQueryResultDataType = .init(name: "Test")
        
        typealias ResultData = TestQueryResultDataType
    }
    
    struct TestCollectionQuery: MKFirestoreQuery {
        typealias ResultData = [TestQueryResultDataType]
        
        var firestoreReference: MKFirestoreReference = .collection("A").document("B").collection("C")
        
        var mockResultData: [TestQueryResultDataType] = [
            .init(name: "A"),
            .init(name: "B"),
            .init(name: "C"),
        ]
    }
    
    struct TestAdvancedQuery: MKFirestoreAdvancedQuery {
        typealias ResultData = [TestQueryResultDataType]
        
        var orderByFieldName: String = "title"
        
        var orderDescending: Bool = false
        
        var startAfterFieldValue: Any? = nil
        
        var limit: Int = 1
        
        var filters: [MFirebaseKit.MKFirestoreQueryFilter] = [
        ]
        
        var firestoreReference: MFirebaseKit.MKFirestoreReference
        
        var mockResultData: [MKFirestoreMockTest.TestQueryResultDataType] = []
    }
    
    struct TestQueryResultDataType: Codable {
        let name: String
    }
    
    struct TestDocumentPermutation: MKFirestorePermutation {
        var firestoreReference: MFirebaseKit.MKFirestoreReference = .collection("Collection").document("Document")
        
        var operation: MFirebaseKit.MKFirestorePermutationOperation = .updateFields([
            .increment(fieldName: "test", by: 1),
            .update(fieldName: "test 2", with: "neu")
        ], merge: true)
    }
    
    struct TestCollectionPermutation: MKFirestorePermutation {
        var firestoreReference: MFirebaseKit.MKFirestoreReference = .collection("Collection")
        
        var operation: MFirebaseKit.MKFirestorePermutationOperation = .addDocument([:])
    }
}
