//
//  File.swift
//  
//
//  Created by Joschua Marz on 12.04.24.
//

import Foundation

public struct MKFirestoreFullMockData {
    public let firestoreReference: MKFirestoreReference
    public let data: [Any]
    
    public init(firestoreReference: MKFirestoreReference, data: [any Codable & Identifiable]) {
        self.firestoreReference = firestoreReference
        self.data = data as [Any]
    }
}

open class MKFirestoreFullMock: MKFirestore {
    public typealias Handler = ([String: [Any]])->Void
    public var dataMap: [String: [Any]] = [:] {
        didSet {
            for listener in activeListeners.values {
                listener.onChange()
            }
        }
    }
    
    public var activeListeners: [String: MockListenerRegistration] = [:]
    
    public init(mockData: [MKFirestoreFullMockData] = []) {
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
    
    open func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T : MKFirestoreCollectionQuery {
        let responseData = dataMap[query.firestoreReference.rawPath] as? [T.BaseResultData]
        return .init(error: nil, responseData: responseData?.applyFilters(query.filters))
    }
    
    open func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T : MKFirestoreDocumentQuery {
        let id = query.firestoreReference.leafId ?? "non-existing-id"
        let objects = dataMap[query.documentReference.leafCollectionPath] as? [T.ResultData]
        return .init(error: nil, responseData: objects?.applyFilters([.isEqualTo("id", id)]).first)
    }
    
    open func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
        let id = deletion.firestoreReference.leafId ?? "non-existing-id"
        dataMap[deletion.documentReference.leafCollectionPath]?.removeAllMatching(fieldName: "id", value: id)
        return nil
    }
    
    @discardableResult
    open func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
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
        return .init(documentId: documentId.flatMap({ "\($0)" }), error: nil)
    }
    
    open func addCollectionListener<T>(_ listener: MKFirestoreCollectionListener<T>) -> MKListenerRegistration where T : MKFirestoreCollectionQuery {
        // register listener
        let registration = MockListenerRegistration(
            onChange: { [weak self] in
                let key = listener.query.firestoreReference.leafCollectionPath
                if let objects = self?.dataMap[key] as? [T.BaseResultData] {
                    listener.objects = objects
                }
            },
            onRemove: { [weak self] in
                self?.activeListeners.removeValue(forKey: listener.id)
            }
        )
        activeListeners.updateValue(registration, forKey: listener.id)
        // fill initially
        registration.onChange()
        // return registration
        return registration
    }
}