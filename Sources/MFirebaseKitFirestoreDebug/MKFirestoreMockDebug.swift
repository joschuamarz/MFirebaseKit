//
//  File.swift
//  
//
//  Created by Joschua Marz on 17.04.24.
//

import Foundation
import XCTest
import MFirebaseKitFirestoreCore

public class MKFirestoreMockDebug: MKFirestoreMock {
    public var expectations: [MKFirestoreExpectation]
    
    public init(
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
        
        super.init()
    }
    
    
    // MARK: - Logging
    
    public override func log(_ response: MKFirestoreMutationResponse, for firestoreReference: MKFirestoreReference) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.expectations.removeFirst(where: { $0.isMatching(path: firestoreReference.rawPath, type: .mutation)})?.fulfill()
        }
        
        super.log(response, for: firestoreReference)
    }
    
    public override func log<Q>(_ response: MKFirestoreDocumentQueryResponse<Q>, for firestoreReference: MKFirestoreReference) where Q : MKFirestoreDocumentQuery {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.expectations.removeFirst(where: { $0.isMatching(path: firestoreReference.rawPath, type: .query) })?.fulfill()
        }
        super.log(response, for: firestoreReference)
    }
    
    public override func log<Q>(_ response: MKFirestoreCollectionQueryResponse<Q>, for firestoreReference: MKFirestoreReference) where Q : MKFirestoreCollectionQuery {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.expectations.removeFirst(where: { $0.isMatching(path: firestoreReference.rawPath, type: .query) })?.fulfill()
        }
        super.log(response, for: firestoreReference)
    }
    
    public override func log(_ deletion: MKFirestoreDocumentDeletion) {
        // fulfill expectation if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.expectations.removeFirst(where: { $0.isMatching(path: deletion.firestoreReference.rawPath, type: .deletion) })?.fulfill()
        }
        // log
        super.log(deletion)
    }
    
    public override func logListenerChange<T: MKFirestoreCollectionQuery>(for listener: MKFirestoreCollectionListener<T>) {
        let path = listener.query.firestoreReference.leafCollectionPath
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let expectation = self.expectations.removeFirst(where: { $0.isMatching(path: path, type: .listener) }) {
                expectation.fulfill()
                print("$ MKFirestoreFullMockDebug: Listener \(listener.id): did fulfill for path: \(path)")
            }
        }
        super.logListenerChange(for: listener)
    }
}
