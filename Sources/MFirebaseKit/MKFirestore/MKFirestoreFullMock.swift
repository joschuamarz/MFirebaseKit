//
//  File.swift
//  
//
//  Created by Joschua Marz on 12.04.24.
//

import FirebaseFirestore
import XCTest

public struct MKFirestoreFullMockData {
    let firestoreReference: MKFirestoreReference
    let data: [Any]
    
    public init(firestoreReference: MKFirestoreReference, data: [any Codable & Identifiable]) {
        self.firestoreReference = firestoreReference
        self.data = data as [Any]
    }
}

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


public class MKFirestoreFullMock: MKFirestore {
    typealias Handler = ([String: [Any]])->Void
    var dataMap: [String: [Any]] = [:] {
        didSet {
            activeListeners.forEach { listener in
                listener.value(dataMap)
            }
        }
    }
    
    var activeListeners: [String:Handler] = [:]
    
    var expectations: [MKFirestoreExpectation]
    
    public init(
        mockData: [MKFirestoreFullMockData] = [],
        expectations: [MKFirestoreExpectation] = []
    ) {
        self.expectations = expectations
        var data: [String: [Any]] = [:]
        for entry in mockData {
            let leafCollectionId = entry.firestoreReference.leafCollectionPath
            if var existingArray = data[leafCollectionId] {
                existingArray.append(contentsOf: entry.data)
                data[leafCollectionId] = existingArray
            } else {
                data[leafCollectionId] = entry.data
            }
        }
        self.dataMap = data
    }
    
    public func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T : MKFirestoreCollectionQuery {
        let responseData = dataMap[query.firestoreReference.rawPath] as? [T.BaseResultData]
        expectations.forEach({ $0.fulfillIfMatching(path: query.firestoreReference.rawPath, type: .query) })
        return .init(error: nil, responseData: responseData?.applyFilters(query.filters))
    }
    
    public func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T : MKFirestoreDocumentQuery {
        let id = query.firestoreReference.leafId ?? "non-existing-id"
        let objects = dataMap[query.documentReference.leafCollectionPath] as? [T.ResultData]
        expectations.forEach({ $0.fulfillIfMatching(path: query.firestoreReference.rawPath, type: .query) })
        return .init(error: nil, responseData: objects?.applyFilters([.isEqualTo("id", id)]).first)
    }
    
    public func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
        let id = deletion.firestoreReference.leafId ?? "non-existing-id"
        dataMap[deletion.documentReference.leafCollectionPath]?.removeAllMatching(fieldName: "id", value: id)
        expectations.forEach({ $0.fulfillIfMatching(path: deletion.firestoreReference.rawPath, type: .deletion) })
        return nil
    }
    
    public func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
        let object = mutation.operation.object as Any
        let id = mutation.firestoreReference.leafId ?? "non-existing-id"
        let key = mutation.firestoreReference.leafCollectionPath
        if let index =  dataMap[key]?.firstIndexMatching(fieldName: "id", value: id) {
            dataMap[key]?[index] = object
        } else if dataMap.keys.contains(key) {
            dataMap[key]?.append(object)
        } else {
            dataMap.updateValue([object], forKey: key)
        }
        let documentId = (object as? any Identifiable)?.id
        expectations.forEach({ $0.fulfillIfMatching(path: mutation.firestoreReference.rawPath, type: .mutation) })
        return .init(documentId: documentId.flatMap({ "\($0)" }), error: nil)
    }
    
    public func addCollectionListener<T>(_ listener: MKFirestoreCollectionListener<T>) -> ListenerRegistration where T : MKFirestoreCollectionQuery {
        // register listener
        activeListeners.updateValue(listener.handleMockChanges(_:), forKey: listener.id)
        // fill initial data
        listener.handleMockChanges(dataMap)
        // return registration
        return MockListenerRegistration(onRemove: {
            self.activeListeners.removeValue(forKey: listener.id)
        })
    }
    
    
}


