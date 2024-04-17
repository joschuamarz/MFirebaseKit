//
//  File.swift
//  
//
//  Created by Joschua Marz on 17.04.24.
//

import Foundation
import XCTest
@_exported import MFirebaseKit

public class MKFirestoreExpectation: XCTestExpectation {
    public enum QueryType: String {
        case deletion, mutation, query
    }
    let firestoreReference: MKFirestoreReference
    let type: QueryType
    
    public init(firestoreReference: MKFirestoreReference, type: QueryType) {
        self.firestoreReference = firestoreReference
        self.type = type
        super.init(description: "\(type) on \(firestoreReference)")
    }
}

extension MKFirestoreExpectation {
    func fulfillIfMatching(path: String, type: QueryType) {
        if self.isMatching(path: path, type: type) {
            self.fulfill()
        }
    }
    func isMatching(path: String, type: QueryType) -> Bool {
        return self.firestoreReference.rawPath == path
        && self.type == type
    }
}

public class MKFirestoreFullMockDebug: MKFirestoreFullMock {
    var expectations: [MKFirestoreExpectation]
    
    public init(
        mockData: [MKFirestoreFullMockData] = [],
        expectations: [MKFirestoreExpectation] = []
    ) {
        self.expectations = expectations
        super.init(mockData: mockData)
    }
    
    public override func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T : MKFirestoreCollectionQuery {
        expectations.forEach({ $0.fulfillIfMatching(path: query.firestoreReference.rawPath, type: .query) })
        return super.executeCollectionQuery(query)
    }
    
    public override func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T : MKFirestoreDocumentQuery {
        expectations.forEach({ $0.fulfillIfMatching(path: query.firestoreReference.rawPath, type: .query) })
        return super.executeDocumentQuery(query)
    }
    
    public override func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
        expectations.forEach({ $0.fulfillIfMatching(path: deletion.firestoreReference.rawPath, type: .deletion) })
        return super.executeDeletion(deletion)
    }
    
    @discardableResult
    public override func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
        expectations.forEach({ $0.fulfillIfMatching(path: mutation.firestoreReference.rawPath, type: .mutation) })
        return super.executeMutation(mutation)
    }
}
