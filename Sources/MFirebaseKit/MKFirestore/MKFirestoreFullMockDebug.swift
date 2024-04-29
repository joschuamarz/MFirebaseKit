//
//  File.swift
//  
//
//  Created by Joschua Marz on 17.04.24.
//

import Foundation
import XCTest
//import FirebaseFirestore
//
//extension Array {
//    mutating func removeFirst(where shouldBeRemoved: (Element) throws -> Bool) rethrows -> Element? {
//        if let index = try firstIndex(where: shouldBeRemoved) {
//            return remove(at: index)
//        }
//        return nil
//    }
//}
//
public protocol MKFirestoreTestableQuery {
    static var testableFirestoreReference: MKFirestoreReference { get }
}

public class MKFirestoreExpectation: XCTestExpectation {
    public enum QueryType: String {
        case deletion, mutation, query, listener
    }
    let firestoreReference: MKFirestoreReference
    let type: QueryType
    
    public init(firestoreReference: MKFirestoreReference, type: QueryType) {
        self.firestoreReference = firestoreReference
        self.type = type
        super.init(description: "\(type) on \(firestoreReference.rawPath)")
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
//
//public class MKFirestoreFullMockDebug: MKFirestoreFullMock {
//    let id = UUID().uuidString
//    
//    public var expectations: [MKFirestoreExpectation]
//    
//    public init(
//        mockData: [MKFirestoreFullMockData] = [],
//        expectations: [MKFirestoreExpectation] = []
//    ) {
//        print("$ MKFirestoreFullMockDebug initialized")
//        self.expectations = expectations
//        if expectations.count > 0 {
//            print("$ MKFirestoreFullMockDebug: \(expectations.count) registered expectations")
//            expectations.forEach { exp in
//                print("$ MKFirestoreFullMockDebug: - \(exp.type) for \(exp.firestoreReference.rawPath)")
//            }
//        }
//        
//        if mockData.count > 0 {
//            print("$ MKFirestoreFullMockDebug: \(mockData.count) mock objects")
//            mockData.forEach { data in
//                print("$ MKFirestoreFullMockDebug: - \(data.data.count) objects for \(data.firestoreReference.rawPath)")
//            }
//        }
//        super.init(mockData: mockData)
//    }
//    
//    public override func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T : MKFirestoreCollectionQuery {
//        log(query)
//        let response = super.executeCollectionQuery(query)
//        log(response)
//        expectations.removeFirst(where: { $0.isMatching(path: query.firestoreReference.rawPath, type: .query) })?.fulfill()
//        return response
//    }
//    
//    public override func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T : MKFirestoreDocumentQuery {
//        let response = super.executeDocumentQuery(query)
//        log(response)
//        expectations.removeFirst(where: { $0.isMatching(path: query.firestoreReference.rawPath, type: .query) })?.fulfill()
//        return response
//    }
//    
//    public override func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
//        let error = super.executeDeletion(deletion)
//        expectations.removeFirst(where: { $0.isMatching(path: deletion.firestoreReference.rawPath, type: .deletion) })?.fulfill()
//        return error
//    }
//    
//    @discardableResult
//    public override func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
//        log(mutation)
//        let response = super.executeMutation(mutation)
//        log(response)
//        expectations.removeFirst(where: { $0.isMatching(path: mutation.firestoreReference.rawPath, type: .mutation)})?.fulfill()
//        return response
//    }
//    
//    public override func addCollectionListener<T>(_ listener: MKFirestoreCollectionListener<T>) -> ListenerRegistration where T : MKFirestoreCollectionQuery {
//        // register listener
//        print("$ Listener \(listener.id) will register")
//        let registration = MockListenerRegistration(
//            onChange: { [weak self] in
//                let path = listener.query.firestoreReference.leafCollectionPath
//                if let objects = self?.dataMap[path] as? [T.BaseResultData] {
//                    listener.objects = objects
//                    if let expectation = self?.expectations.removeFirst(where: { $0.isMatching(path: path, type: .listener) }) {
//                        expectation.fulfill()
//                        print("$ Listener \(listener.id): did fulfill for path: \(path) of \(self?.id ?? "unknown")")
//                    }
//                }
//                print("$ Listener \(listener.id) did change with \(listener.objects.count) objects")
//            },
//            onRemove: { [weak self] in
//                self?.activeListeners.removeValue(forKey: listener.id)
//            }
//        )
//        activeListeners.updateValue(registration, forKey: listener.id)
//        // fill initially
//        registration.onChange()
//        // return registration
//        return registration
//    }
//    
//    // MARK: - Logging
//    private func log(_ query: MKFirestoreQuery) {
//        print("$ MKFirestoreFullMockDebug: \(query.executionLogMessage) ")
//    }
//    
//    private func log(_ response: MKFirestoreMutationResponse) {
//        print("$ MKFirestoreFullMockDebug: \(response.responseLogMessage) ")
//    }
//    
//    private func log<Q: MKFirestoreDocumentQuery>(_ response: MKFirestoreDocumentQueryResponse<Q>) {
//        print("$ MKFirestoreFullMockDebug: \(response.responseLogMessage) ")
//    }
//    
//    private func log<Q: MKFirestoreCollectionQuery>(_ response: MKFirestoreCollectionQueryResponse<Q>) {
//        print("$ MKFirestoreFullMockDebug: \(response.responseLogMessage) ")
//    }
//}
