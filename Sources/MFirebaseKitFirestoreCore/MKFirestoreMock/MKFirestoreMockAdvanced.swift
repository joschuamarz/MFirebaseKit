//
//  MKFirestoreMockAdvanced.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 30.07.25.
//

import Foundation

open class MKFirestoreMockAdvanced: MKFirestore {
    public typealias ChangeHandler = () -> Void

    /// Maps collection paths to listeners
    private var listeners: [String: [MockListenerRegistration]] = [:]
    
    /// Maps collection paths to a collection.
    /// A collection consists of a map between documentId and objects
    private var objects: [String: [String: Any]] = [:]
    
    public enum AutoResponse {
        /// Responds with the mock results of the provided Query
        case success
        case error(MKFirestoreError)
    }
    
    /// Maps between a document path and the auto response
    private var documentQueryAutoResponseMap: [String: AutoResponse] = [:]
    /// Maps between a collection path and the auto response
    private var collectionQueryAutoResponseMap: [String: AutoResponse] = [:]

    /**
     Initializes a Firestore mock with the ability to provide initial data per collection.
     */
    public init(mockData: [MKFirestoreFullMockData] = []) {
        for entry in mockData {
            let path = entry.firestoreReference.leafCollectionPath
            if var existing = objects[path] {
                // Merge new objects with exsiting ones in the same collection
                existing.merge(entry.data) { old, new in
                    // If a documentID already exists, we override it with the new object
                    return new
                }
                objects[path] = existing
            } else {
                // Define objects at path
                objects[path] = entry.data
            }
        }
        // notify listeners about added objects
        for collectionPath in objects.keys {
            if let collectionObjects = objects[collectionPath]?.values {
            let documentChanges = collectionObjects.map({ MKDocumentChangeMock(changeType: .added, object: $0) })
                notifyListeners(for: collectionPath, with: documentChanges)
            }
        }
    }
    
    public convenience init(autoResponse: AutoResponse, for query: any MKFirestoreCollectionQuery) {
        collectionQueryAutoResponseMap = [query.firestoreReference.rawPath: autoResponse]
    }
    
    public convenience init(autoResponse: AutoResponse, for query: any MKFirestoreDocumentQuery) {
        documentQueryAutoResponseMap = [query.firestoreReference.rawPath: autoResponse]
    }
    
    open func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T: MKFirestoreCollectionQuery {
        
        // Check if an auto-response has been registered
        if let autoResponse = collectionQueryAutoResponseMap[query.firestoreReference.rawPath] {
            switch autoResponse {
            case .success:
                return .init(error: nil, responseData: query.mockResultData)
            case .error(let error):
                return .init(error: error, responseData: nil)
            }
        }
        
        // Get document id map for given firestore path
        let documentIdMap = objects[query.firestoreReference.rawPath] as? [String: T.BaseResultData]
        // Get objects associated with each document
        let objects = documentIdMap?.values as? [T.BaseResultData]
        // Apply filters
        let filteredResults = objects?.applyFilters(query.filters)
        // Return results
        return .init(error: nil, responseData: filteredResults)
    }

    open func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T: MKFirestoreDocumentQuery {
        
        // Check if an auto-response has been registered
        if let autoResponse = documentQueryAutoResponseMap[query.firestoreReference.rawPath] {
            switch autoResponse {
            case .success:
                return .init(error: nil, responseData: query.mockResultData)
            case .error(let error):
                return .init(error: error, responseData: nil)
            }
        }
        
        // Get referenced collection Id
        let collectionId = query.documentReference.leafCollectionPath
        // Get required document id
        guard let documentId = query.documentReference.leafId else {
            return .init(error: .firestoreError("No document id provided"), responseData: nil)
        }
        
        // Get document id map for given firestore path
        let documentIdMap = objects[query.firestoreReference.rawPath] as? [String: T.ResultData]
        // Try to get object at given document id
        let object = documentIdMap?[documentId]
        
        return .init(error: nil, responseData: object)
    }

    open func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
        // Get referenced collection path
        let collectionPath = deletion.documentReference.leafCollectionPath
        // Get required document id
        guard let documentId = deletion.documentReference.leafId else {
            return .firestoreError("No document id provided")
        }
        // Remove object in collection with document id
        removeObject(collectionPath: collectionPath, documentId: documentId)
        return nil
    }

    open func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
        if let documentReference = mutation.firestoreReference as? MKFirestoreDocumentReference {
            return handleDocumentMutation(reference: documentReference, operation: mutation.operation)
        } else if let collectionReference = mutation.firestoreReference as? MKFirestoreCollectionReference {
            
        }
        return .init(documentId: nil, error: .internalError("Unknown firestore reference"))
    }
    
    private func handleDocumentMutation(reference: MKFirestoreDocumentReference, operation: MKFirestoreMutationOperation) -> MKFirestoreMutationResponse {
        // Get referenced collection path
        let collectionPath = reference.leafCollectionPath
        // Get required document id
        guard let documentId = reference.leafId else {
            return .init(documentId: nil, error: .firestoreError("No document id provided"))
        }
        // Write object at given document id in collection
        writeObject(collectionPath: collectionPath, documentId: documentId, object: operation.object as Any)
        return .init(documentId: documentId, error: nil)
    }
    
    private func handleCollectionMutation(reference: MKFirestoreCollectionReference, operation: MKFirestoreMutationOperation) -> MKFirestoreMutationResponse {
        // Get referenced collection path
        let collectionPath = reference.leafCollectionPath
        // Generate document id from identifiable object
        let documentId = ((operation.object as? any Identifiable)?.id as? String) ?? UUID().uuidString
        // Write object at document id in collection
        writeObject(collectionPath: collectionPath, documentId: documentId, object: operation.object as Any)
        return .init(documentId: documentId, error: nil)
    }

    open func addCollectionListener<T>(_ listener: MKFirestoreCollectionListener<T>) -> MKListenerRegistration where T: MKFirestoreCollectionQuery {
        // Get collection path
        let collectionPath = listener.query.collectionReference.leafCollectionPath
        
        let registration = MockListenerRegistration(
            id: listener.id,
            onChange: { documentChanges in
                // filter relevant changes
                let relevantChanges = documentChanges.filter { change in
                    // The change must be connected to a result data type
                    guard let object = try? change.object(as: T.BaseResultData.self) else {
                        return false
                    }
                    // Check if the object gets filtered out
                    return ![object].applyFilters(listener.query.filters).isEmpty
                }
                // Only notify listener if changes are not empty
                guard !relevantChanges.isEmpty else { return }
                listener.handle(relevantChanges, error: nil, for: listener.query)
            },
            onRemove: { [weak self] in
                guard let self else { return }
                // Get currently registered listeners for collection path
                var activeListeners = listeners[collectionPath]
                // Remove this listener
                activeListeners?.removeAll(where: { $0.id == listener.id })
                // Re-assign listeners
                listeners[collectionPath] = activeListeners
            }
        )
        
        // Set Listener registration at collection path
        if listeners[collectionPath] == nil {
            // No listener yet, just assign it
            listeners[collectionPath] = [registration]
        } else if !(listeners[collectionPath] ?? []).contains(where: { $0.id == listener.id }) {
            // Only register listener if it isn't registered yet
            listeners[collectionPath]?.append(registration)
        }
        return registration
    }
    
    private func writeObject(collectionPath: String, documentId: String, object: Any) {
        // check if object exists
        let didExist = objects[collectionPath]?[documentId] != nil
        // write object
        objects[collectionPath]?[documentId] = object
        // make document change
        let documentChange = MKDocumentChangeMock(changeType: didExist ? .modified : .added, object: object)
        notifyListeners(for: collectionPath, with: [documentChange])
    }
    
    private func removeObject(collectionPath: String, documentId: String) {
        // Remove object if exists
        guard let object = objects[collectionPath]?.removeValue(forKey: documentId) else { return }
        let documentChange = MKDocumentChangeMock(changeType: .removed, object: object)
        notifyListeners(for: collectionPath, with: [documentChange])
    }
    
    private func notifyListeners(for collectionPath: String, with documentChanges: [MKDocumentChange]) {
        // find relevant listeners
        let relevantListeners = listeners[collectionPath] ?? []
        // notify listeners
        for listener in relevantListeners {
            listener.onChange(documentChanges)
        }
    }
}

// Extensions for filtering/matching (used above)
extension Array where Element: Codable {
    func applyFilters(_ filters: [MKFirestoreQueryFilter]) -> [Element] {
        // Dummy implementation – you should extend this based on your real filters
        return self
    }

    mutating func removeAllMatching(fieldName: String, value: Any) {
        self.removeAll {
            let mirror = Mirror(reflecting: $0)
            return mirror.children.contains { $0.label == fieldName && ("\($0.value)" == "\(value)") }
        }
    }

    func firstIndexMatching(fieldName: String, value: Any) -> Int? {
        self.firstIndex {
            let mirror = Mirror(reflecting: $0)
            return mirror.children.contains { $0.label == fieldName && ("\($0.value)" == "\(value)") }
        }
    }
}    

// Helper registration
public final class MockListenerRegistration: MKListenerRegistration {
    public let id: String
    public let onChange: ([MKDocumentChange]) -> Void
    public let onRemove: () -> Void
    
    public init(id: String, onChange: @escaping ([MKDocumentChange]) -> Void, onRemove: @escaping () -> Void = {}) {
        self.id = id
        self.onChange = onChange
        self.onRemove = onRemove
    }

    public func remove() {
        onRemove()
    }
}

struct MKDocumentChangeMock: MKDocumentChange {
    let changeType: MKDocumentChangeType
    let object: Any
    
    func object<T>(as type: T.Type) throws -> T where T : Decodable {
        guard let object = object as? T else {
            throw MKFirestoreError.internalError("MKDocumentChangeMock: Object does not match expected type \(type)")
        }
        return object
    }
}
