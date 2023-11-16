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
        var response: MKFirestoreDocumentQueryResponse<TestDocumentQuery>?
        firestore.executeDocumentQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: query.mockResultData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.responseData?.name, query.mockResultData.name)
    }
    
    func testUnauthenticatedDocumentQuery() {
        let firestore = MKFirestoreMock()
        let query = TestDocumentQuery()
        var response: MKFirestoreDocumentQueryResponse<TestDocumentQuery>?
        firestore.executeDocumentQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
    }
    
    func testCollectionQuery() {
        let firestore = MKFirestoreMock()
        let query = TestCollectionQuery()
        var response: MKFirestoreCollectionQueryResponse<TestCollectionQuery>?
        firestore.executeCollectionQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: query.mockResultData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.responseData?.count, query.mockResultData.count)
    }
    
    func testUnauthenticatedCollectionQuery() {
        let firestore = MKFirestoreMock()
        let query = TestCollectionQuery()
        var response: MKFirestoreCollectionQueryResponse<TestCollectionQuery>?
        firestore.executeCollectionQuery(query) { data in
            response = data
        }
        firestore.respond(to: query, with: .unauthenticated)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.responseData)
        
    }
    
    func testDocumentPermutationAutoError() {
        let firestore = MKFirestoreMock(autoResponse: .error(.firestoreError(.init(.aborted))))
        let permutation = TestDocumentPermutation()
        var response: MKFirestoreMutationResponse?
        firestore.executeMutation(permutation) { newResponse in
            response = newResponse
        }
        
        XCTAssertNil(response?.documentId)
        XCTAssertNotNil(response?.error)
    }
    
    // MARK: - Helper
    
    struct TestDocumentQuery: MKFirestoreDocumentQuery {
        typealias ResultData = TestQueryResultDataType
        var documentReference: MKFirestoreDocumentReference = .collection("Collection1").document("doc")
        
        var mockResultData: TestQueryResultDataType = .init(name: "Test")
    }
    
    struct TestCollectionQuery: MKFirestoreCollectionQuery {
        var collectionReference: MKFirestoreCollectionReference = .collection("A").document("B").collection("C")
        
        var orderDescriptor: OrderDescriptor? = nil
        
        var limit: Int?
        
        
        var filters: [MKFirestoreQueryFilter] = []
        
        typealias ResultData = TestQueryResultDataType
        
        
        var mockResultData: [TestQueryResultDataType] = [
            .init(name: "A"),
            .init(name: "B"),
            .init(name: "C"),
        ]
    }
    
    struct TestQueryResultDataType: Codable {
        let name: String
    }
    
    struct TestDocumentPermutation: MKFirestoreDocumentMutation {
        var firestoreReference: MFirebaseKit.MKFirestoreReference = .collection("Collection").document("Document")
        
        var operation: MFirebaseKit.MKFirestoreMutationOperation = .updateFields([
            .increment(fieldName: "test", by: 1),
            .update(fieldName: "test 2", with: "neu")
        ], merge: true)
    }
    
    struct TestCollectionPermutation: MKFirestoreDocumentMutation {
        var firestoreReference: MFirebaseKit.MKFirestoreReference = .collection("Collection")
        
        var operation: MFirebaseKit.MKFirestoreMutationOperation = .addDocument([:])
    }
}


