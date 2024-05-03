//
//  File.swift
//  
//
//  Created by Joschua Marz on 17.04.24.
//

import Foundation
import XCTest
import MFirebaseKitFirestoreCore

public class MKFirestoreFullMockDebug: MKFirestoreFullMock {
    public var expectations: [MKFirestoreExpectation]
    
    public init(
        mockData: [MKFirestoreFullMockData] = [],
        expectations: [MKFirestoreExpectation] = []
    ) {
        print("$ MKFirestoreFullMockDebug initialized")
        self.expectations = expectations
        if expectations.count > 0 {
            print("$ MKFirestoreFullMockDebug: \(expectations.count) registered expectations")
            expectations.forEach { exp in
                print("$ MKFirestoreFullMockDebug: - \(exp.type) for \(exp.firestoreReference.rawPath)")
            }
        }
        
        if mockData.count > 0 {
            print("$ MKFirestoreFullMockDebug: \(mockData.count) mock objects")
            mockData.forEach { data in
                print("$ MKFirestoreFullMockDebug: - \(data.data.count) objects for \(data.firestoreReference.rawPath)")
            }
        }
        super.init(mockData: mockData)
    }
    
    
    // MARK: - Logging
    
    public override func log(_ response: MKFirestoreMutationResponse, for firestoreReference: MKFirestoreReference) {
        expectations.removeFirst(where: { $0.isMatching(path: firestoreReference.rawPath, type: .mutation)})?.fulfill()
        super.log(response, for: firestoreReference)
    }
    
    public override func log<Q>(_ response: MKFirestoreDocumentQueryResponse<Q>, for firestoreReference: MKFirestoreReference) where Q : MKFirestoreDocumentQuery {
        expectations.removeFirst(where: { $0.isMatching(path: firestoreReference.rawPath, type: .query) })?.fulfill()
        super.log(response, for: firestoreReference)
    }
    
    public override func log<Q>(_ response: MKFirestoreCollectionQueryResponse<Q>, for firestoreReference: MKFirestoreReference) where Q : MKFirestoreCollectionQuery {
        expectations.removeFirst(where: { $0.isMatching(path: firestoreReference.rawPath, type: .query) })?.fulfill()
        super.log(response, for: firestoreReference)
    }
    
    public override func log(_ deletion: MKFirestoreDocumentDeletion) {
        // fulfill expectation if needed
        expectations.removeFirst(where: { $0.isMatching(path: deletion.firestoreReference.rawPath, type: .deletion) })?.fulfill()
        // log
        super.log(deletion)
    }
    
    public override func logListenerChange<T: MKFirestoreCollectionQuery>(for listener: MKFirestoreCollectionListener<T>) {
        let path = listener.query.firestoreReference.leafCollectionPath
        if let expectation = self.expectations.removeFirst(where: { $0.isMatching(path: path, type: .listener) }) {
            expectation.fulfill()
            print("$ MKFirestoreFullMockDebug: Listener \(listener.id): did fulfill for path: \(path)")
        }
        super.logListenerChange(for: listener)
    }
}
