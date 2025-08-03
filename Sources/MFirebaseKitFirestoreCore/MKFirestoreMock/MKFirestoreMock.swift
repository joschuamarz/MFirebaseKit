//
//  MKFirestoreMockAdvanced.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 30.07.25.
//

import Foundation



open class MKFirestoreMock: MKFirestore {
    public typealias ChangeHandler = () -> Void

    /// Maps collection paths to listeners
    private var listeners: [String: [MKListenerRegistrationMock]] = [:]
    
    /// Maps collection paths to a collection.
    /// A collection consists of a map between documentId and objects
    private var objects: [String: [String: Any]] = [:]
    
    public enum AutoResponse {
        /// Responds with the mock results of the provided Query
        case successUsingMock
        case success(data: [any (Codable & Identifiable)])
        case error(MKFirestoreError)
    }
    
    public enum MockChangeType {
        case modified(documentID: String, data: any (Codable & Identifiable))
        case added(documentID: String, data: any (Codable & Identifiable))
        case removed(documentID: String)
    }
    
    /// Maps between a document path and the auto response
    private var documentQueryAutoResponseMap: [String: AutoResponse] = [:]
    /// Maps between a collection path and the auto response
    private var collectionQueryAutoResponseMap: [String: AutoResponse] = [:]

    /**
     Initializes a Firestore mock.
     */
    public init() {}
    
    public func register(autoResponse: AutoResponse, for query: any MKFirestoreCollectionQuery) {
        collectionQueryAutoResponseMap[query.firestoreReference.rawPath] = autoResponse
    }
    
    public func register(autoResponse: AutoResponse, for collectionReference: MKFirestoreCollectionReference) {
        collectionQueryAutoResponseMap[collectionReference.rawPath] = autoResponse
    }
    
    public func register(initialData: [String: any (Codable & Identifiable)], for collectionReference: MKFirestoreCollectionReference) {
        objects[collectionReference.rawPath] = initialData as [String: Any]
    }
    
    public func simulateChange(
        for collectionReference: MKFirestoreCollectionReference,
        changeType: MockChangeType
    ) {
        switch changeType {
        case .modified(let documentID, let data), .added(let documentID, let data):
            self.writeObject(collectionPath: collectionReference.rawPath, documentId: documentID, object: data)
        case .removed(let documentID):
            self.removeObject(collectionPath: collectionReference.rawPath, documentId: documentID)
        }
    }
    
    public convenience init(autoResponse: AutoResponse, for query: any MKFirestoreDocumentQuery) {
        self.init()
        documentQueryAutoResponseMap = [query.firestoreReference.rawPath: autoResponse]
    }
    
    open func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T: MKFirestoreCollectionQuery {
        log(query)
        // Check if an auto-response has been registered
        if let autoResponse = makeCollectionAutoResponse(for: query) {
            log(autoResponse, for: query.firestoreReference)
            return autoResponse
        }
        
        // Get document id map for given firestore path
        let documentIdMap = objects[query.firestoreReference.rawPath] as? [String: T.BaseResultData]
        // Get objects associated with each document
        let objects = documentIdMap?.values as? [T.BaseResultData]
        // Apply filters
        let filteredResults = objects?.applyFilters(query.filters)
        // Return results
        let response = MKFirestoreCollectionQueryResponse<T>(error: nil, responseData: filteredResults)
        log(response, for: query.firestoreReference)
        return response
    }

    open func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T: MKFirestoreDocumentQuery {
        log(query)
        // Check if an auto-response has been registered
        if let autoResponse = makeDocumentAutoResponse(for: query) {
            log(autoResponse, for: query.firestoreReference)
            return autoResponse
        }
        
        // Get required document id
        guard let documentId = query.documentReference.leafId else {
            return .init(error: .firestoreError("No document id provided"), responseData: nil)
        }
        
        // Get document id map for given firestore path
        let documentIdMap = objects[query.firestoreReference.rawPath] as? [String: T.ResultData]
        // Try to get object at given document id
        let object = documentIdMap?[documentId]
        
        let response = MKFirestoreDocumentQueryResponse<T>(error: nil, responseData: object)
        log(response, for: query.firestoreReference)
        return response
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
        log(deletion)
        return nil
    }

    open func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
        log(mutation)
        let response: MKFirestoreMutationResponse
        if let documentReference = mutation.firestoreReference as? MKFirestoreDocumentReference {
            response = handleDocumentMutation(reference: documentReference, operation: mutation.operation)
        } else if let collectionReference = mutation.firestoreReference as? MKFirestoreCollectionReference {
            response = handleCollectionMutation(reference: collectionReference, operation: mutation.operation)
        } else {
            response = .init(documentId: nil, error: .internalError("Unknown firestore reference"))
        }
        log(response, for: mutation.firestoreReference)
        return response
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
        
        let registration = MKListenerRegistrationMock(
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
                DispatchQueue.main.async {
                    listener.handle(relevantChanges, error: nil, for: listener.query)
                    self.logListenerChange(for: listener)
                }
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
        
        // Notify listener with initial objects
        if let initialObjects = objects[collectionPath] {
            // make this MKDocumentChangeMock(changeType: .added, object: $0.value, documentID: $0.key)
            let documentChanges = initialObjects.compactMap {
                MKDocumentChangeMock(
                    changeType: .added,
                    object: $0.value,
                    documentID: $0.key
                )
            }
            // handle initial changes
            registration.onChange(documentChanges)
        }
        
        return registration
    }
    
    private func writeObject(collectionPath: String, documentId: String, object: Any) {
        DispatchQueue.main.async {
            // check if object exists
            let didExist = self.objects[collectionPath]?[documentId] != nil
            // write object
            self.objects[collectionPath]?[documentId] = object
            // make document change
            let documentChange = MKDocumentChangeMock(
                changeType: didExist ? .modified : .added,
                object: object,
                documentID: documentId
            )
            self.notifyListeners(for: collectionPath, with: [documentChange])
        }
    }
    
    private func removeObject(collectionPath: String, documentId: String) {
        DispatchQueue.main.async {
            // Remove object if exists
            guard let object = self.objects[collectionPath]?.removeValue(forKey: documentId) else { return }
            let documentChange = MKDocumentChangeMock(
                changeType: .removed,
                object: object,
                documentID: documentId
            )
            self.notifyListeners(for: collectionPath, with: [documentChange])
        }
    }
    
    private func notifyListeners(for collectionPath: String, with documentChanges: [MKDocumentChange]) {
        // find relevant listeners
        let relevantListeners = listeners[collectionPath] ?? []
        // notify listeners
        for listener in relevantListeners {
            listener.onChange(documentChanges)
        }
    }
    
    
    private func makeCollectionAutoResponse<T: MKFirestoreCollectionQuery>(
        for query: T
    ) -> MKFirestoreCollectionQueryResponse<T>?  {
        guard let autoResponse = collectionQueryAutoResponseMap[query.firestoreReference.rawPath] else {
            return nil
        }
    
        switch autoResponse {
        case .successUsingMock:
            return .init(error: nil, responseData: query.mockResultData)
        case .success(let data):
            if let data = data as? [T.BaseResultData] {
                return .init(error: nil, responseData: data)
            } else {
                return .init(error: nil, responseData: query.mockResultData)
            }
        case .error(let error):
            return .init(error: error, responseData: nil)
        }
    }
    
    
    private func makeDocumentAutoResponse<T: MKFirestoreDocumentQuery>(
        for query: T
    ) -> MKFirestoreDocumentQueryResponse<T>?  {
        guard let autoResponse = collectionQueryAutoResponseMap[query.firestoreReference.rawPath] else {
            return nil
        }
        
        switch autoResponse {
        case .successUsingMock:
            return .init(error: nil, responseData: query.mockResultData)
        case .success(let data):
            if let data = data as? [T.ResultData] {
                return .init(error: nil, responseData: data.first)
            } else {
                return .init(error: nil, responseData: query.mockResultData)
            }
        case .error(let error):
            return .init(error: error, responseData: nil)
        }
    }
    
    // MARK: - Logging
    open func log(_ query: MKFirestoreQuery) {
        print("$ MKFirestoreFullMockDebug: \(query.executionLogMessage) ")
    }
    
    open func log(_ response: MKFirestoreMutationResponse, for firestoreReference: MKFirestoreReference) {
        print("$ MKFirestoreFullMockDebug: \(response.responseLogMessage) ")
    }
    
    open func log<Q: MKFirestoreDocumentQuery>(_ response: MKFirestoreDocumentQueryResponse<Q>, for firestoreReference: MKFirestoreReference) {
        print("$ MKFirestoreFullMockDebug: \(response.responseLogMessage) ")
    }
    
    open func log<Q: MKFirestoreCollectionQuery>(_ response: MKFirestoreCollectionQueryResponse<Q>, for firestoreReference: MKFirestoreReference) {
        print("$ MKFirestoreFullMockDebug: \(response.responseLogMessage) ")
    }
    
    open func log(_ deletion: MKFirestoreDocumentDeletion) {
        print("$ MKFirestoreFullMockDebug:  \(deletion.executionLogMessage) ")
    }
    
    open func logListenerChange<T: MKFirestoreCollectionQuery>(for listener: MKFirestoreCollectionListener<T>) {
        print("$ MKFirestoreFullMockDebug: Listener \(listener.id) did change with \(listener.objects.count) objects")
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
public final class MKListenerRegistrationMock: MKListenerRegistration {
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



