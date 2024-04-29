//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

@available(macOS 10.15, *)
extension Firestore: MKFirestore {
        
    // MARK: - Mutations
    
    /// Asynchonously executes a Mutation and returns the corresponding `MKFirestoreMutationResponse`.
    ///
    /// This method can execute a mutation both on a `Collection` and `Document`.
    /// - Parameter mutation: The mutation that should be executed.
    /// - Returns: A `MKFirestoreMutationResponse` containing the affected `documentId` on success
    /// and an `MKFirestoreError` on failure.
    public func executeMutation(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse {
        if mutation.firestoreReference is MKFirestoreCollectionReference {
            return await executeCollectionMutation(mutation)
        } else {
            return await executeDocumentMutation(mutation)
        }
    }
        
    // MARK: - Deletions
    
    public func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) async -> MKFirestoreError? {
        do {
            try await self.document(deletion.documentReference.rawPath).delete()
            return nil
        } catch {
            return MKFirestoreError.parsingError(error)
        }
    }
    
    /// Executes the given mutation on a collection
    /// 
    private func executeCollectionMutation(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse {
        do {
            if let data = mutation.operation.data {
                let documentId = try await self.collection(mutation.firestoreReference.rawPath).addDocument(data: data).documentID
                return MKFirestoreMutationResponse(documentId: documentId, error: nil)
            } else if let object = mutation.operation.object {
                let documentId = try self.collection(mutation.firestoreReference.rawPath).addDocument(from: object).documentID
                return MKFirestoreMutationResponse(documentId: documentId, error: nil)
            }
            return MKFirestoreMutationResponse(documentId: nil, error: .firestoreError(FirestoreErrorCode(FirestoreErrorCode.invalidArgument)))
        } catch (let error) {
            return MKFirestoreMutationResponse(documentId: nil, error: handleError(error, for: mutation))
        }
    }
    
    private func executeDocumentMutation(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse {
        do {
            if let data = mutation.operation.data {
                try await self.document(mutation.firestoreReference.rawPath).setData(data, merge: mutation.operation.merge)
                return MKFirestoreMutationResponse(documentId: mutation.firestoreReference.leafId, error: nil)
            } else if let object = mutation.operation.object {
                try self.document(mutation.firestoreReference.rawPath).setData(from: object, merge: mutation.operation.merge)
                return MKFirestoreMutationResponse(documentId: mutation.firestoreReference.leafId, error: nil)
            }
            return MKFirestoreMutationResponse(documentId: nil, error: .firestoreError(FirestoreErrorCode(FirestoreErrorCode.invalidArgument)))
        } catch (let error) {
            return MKFirestoreMutationResponse(documentId: nil, error: handleError(error, for: mutation))
        }
    }
    
    // MARK: - Document Query
    
    public func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T) async -> MKFirestoreDocumentQueryResponse<T> {
        let documentReference = self.document(query.firestoreReference.rawPath)
        print("$ MKFirestore: Executing document Query with path \(query.firestoreReference.rawPath)")
        do {
            let document = try await documentReference.getDocument()
            let result = try document.data(as: T.ResultData.self)
            print("$ MKFirestore: Successfully finished document Query for path \(query.firestoreReference.rawPath)")
            return MKFirestoreDocumentQueryResponse(error: nil, responseData: result)
        } catch (let error) {
            return MKFirestoreDocumentQueryResponse<T>(error: handleError(error, for: query), responseData: nil)
        }
    }
    
    // MARK: - Collection Query
    
    public func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T) async -> MKFirestoreCollectionQueryResponse<T> {
        let collectionReference = self.collection(query.firestoreReference.rawPath)
        var firestoreQuery: Query = collectionReference
        if let orderDescriptor = query.orderDescriptor {
            // Order
            firestoreQuery = collectionReference.order(by: orderDescriptor.orderByFieldName, descending: orderDescriptor.orderDescending)
            // Start After
            if let startAfterFieldValue = orderDescriptor.startAfterFieldValue {
                firestoreQuery = firestoreQuery.start(after: [startAfterFieldValue])
            }
        }
        // Filter
        for filter in query.filters {
            firestoreQuery = firestoreQuery.applyFilter(filter)
        }
        // Limit
        if let limit = query.limit {
            firestoreQuery = firestoreQuery.limit(to: limit)
        }
        print("$ MKFirestore: Executing collection Query with path \(query.firestoreReference.rawPath)")
        do {
            let documents: [QueryDocumentSnapshot] = try await firestoreQuery.getDocuments().documents
            
            let results = try documents.map({ try $0.data(as: T.BaseResultData.self) })
            print("$ MKFirestore: Successfully finished document Query for path \(query.firestoreReference.rawPath)")
            print("$ MKFirestore: Fetched \(documents.count) objects in the new way")
            return MKFirestoreCollectionQueryResponse(error: nil, responseData: results)
        } catch (let error) {
            return MKFirestoreCollectionQueryResponse<T>(error: handleError(error, for: query), responseData: nil)
        }
    }
    
    public func addCollectionListener<T: MKFirestoreCollectionQuery>(_ listener: MKFirestoreCollectionListener<T>) -> ListenerRegistration {
        let query = listener.query
        let collectionReference = self.collection(query.firestoreReference.rawPath)
        var firestoreQuery: Query = collectionReference
        if let orderDescriptor = query.orderDescriptor {
            // Order
            firestoreQuery = collectionReference.order(by: orderDescriptor.orderByFieldName, descending: orderDescriptor.orderDescending)
            // Start After
            if let startAfterFieldValue = orderDescriptor.startAfterFieldValue {
                firestoreQuery = firestoreQuery.start(after: [startAfterFieldValue])
            }
        }
        // Filter
        for filter in query.filters {
            firestoreQuery = firestoreQuery.applyFilter(filter)
        }
        
        // Limit
        if let limit = query.limit {
            firestoreQuery = firestoreQuery.limit(to: limit)
        }
        
        return firestoreQuery.addSnapshotListener { snapshot, error in
            listener.handle(snapshot?.documentChanges, error: error, for: listener.query)
        }
    }
    
    // MARK: - Handle Error
    private func handleError<T: MKFirestoreQuery>(_ error: Error, for query: T) -> MKFirestoreError {
        print("$ MKFirestore: Finished collection Query for path \(query.firestoreReference.rawPath) with Error")
        var specificError: MKFirestoreError
        if let firestoreError = error as? FirebaseFirestore.FirestoreErrorCode {
            specificError = .firestoreError(firestoreError)
        } else {
            specificError = .parsingError(error)
        }
        print("$ MKFirestore: \(specificError.localizedDescription)")
        return specificError
    }
    
    public func getBaseType<T>(of collection: T.Type) -> Any.Type? {
        if let arrayType = T.self as? [Any].Type {
            return arrayType.Element.self
        }
        return nil
    }
}
