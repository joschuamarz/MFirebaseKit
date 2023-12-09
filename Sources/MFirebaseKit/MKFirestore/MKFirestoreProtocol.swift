//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import Foundation
import FirebaseFirestore

public protocol MKFirestore {
    
    // MARK: - Mutations
    
    /// Asynchonously executes a Mutation and returns the corresponding `MKFirestoreMutationResponse`.
    ///
    /// This method can execute a mutation both on a `Collection` and `Document`.
    /// - Parameter mutation: The mutation that should be executed.
    /// - Returns: A `MKFirestoreMutationResponse` containing the affected `documentId` on success
    /// and an `MKFirestoreError` on failure.
    func executeMutation(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse
    
    /// Asynchonously executes a Mutation and calls the completion handler with corresponding `MKFirestoreMutationResponse`.
    ///
    /// This method can execute a mutation both on a `Collection` and `Document`.
    /// - Parameter mutation: The mutation that should be executed.
    /// - Parameter completion: Completion handler that gets called when the execution ended.
    /// - Returns: A `MKFirestoreMutationResponse` containing the affected `documentId` on success
    /// and an `MKFirestoreError` on failure.
    func executeMutation(_ mutation: MKFirestoreDocumentMutation, completion: @escaping (MKFirestoreMutationResponse)->Void)
    
    // MARK: - Deletions
    
    func executeDeletion(_ deletion: MKFirestoreDocumentDeletion)
    
    func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) async -> MKFirestoreError?
    
    func executeDeletion(_ deletion: MKFirestoreDocumentDeletion, completion: @escaping (MKFirestoreError?)->Void)
    
    // MARK: - Document Queries
    
    func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T) async -> MKFirestoreDocumentQueryResponse<T>
    
    func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T, completion: @escaping (MKFirestoreDocumentQueryResponse<T>)->Void)
    
    // MARK: - Collection Queries
    
    func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T) async -> MKFirestoreCollectionQueryResponse<T>
    
    func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T, completion: @escaping (MKFirestoreCollectionQueryResponse<T>)->Void)
    
    // MARK: - Listener
    
    func addCollectionListener<T: MKFirestoreCollectionQuery>(_ listener: MKFirestoreCollectionListener<T>) -> ListenerRegistration
}

// MARK:  Default Implementations

extension MKFirestore {
    
    // MARK: - Mutations
    
    public func executeMutation(_ mutation: MKFirestoreDocumentMutation, completion: @escaping (MKFirestoreMutationResponse)->Void) {
        Task {
            let response = await executeMutation(mutation)
            completion(response)
        }
    }
    
    // MARK: - Deletions
    
    public func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) {
        Task {
            _ = await executeDeletion(deletion)
        }
    }
    
    public func executeDeletion(_ deletion: MKFirestoreDocumentDeletion, completion: @escaping (MKFirestoreError?)->Void) {
        Task {
            let response = await executeDeletion(deletion)
            completion(response)
        }
    }
    
    // MARK: - Document Queries
    
    public func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T, completion: @escaping (MKFirestoreDocumentQueryResponse<T>)->Void) {
        Task {
            let response = await executeDocumentQuery(query)
            completion(response)
        }
    }
    
    // MARK: - Collection Queries
    public func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T, completion: @escaping (MKFirestoreCollectionQueryResponse<T>)->Void) {
        Task {
            let response = await executeCollectionQuery(query)
            completion(response)
        }
    }
}

public struct MKPaginatedQuery<Query: MKFirestoreCollectionQuery>: MKFirestoreCollectionQuery {
    public typealias BaseResultData = Query.BaseResultData
    
    public var collectionReference: MKFirestoreCollectionReference
    public var orderDescriptor: OrderDescriptor?
    public var filters: [MKFirestoreQueryFilter]
    public var limit: Int?
    let lastDocument: DocumentSnapshot?
    
    init(query: Query, limit: Int?, startAfter document: DocumentSnapshot?) {
        self.collectionReference = query.collectionReference
        self.mockResultData = query.mockResultData
        self.orderDescriptor = query.orderDescriptor
        self.filters = query.filters
        self.limit = limit
        self.lastDocument = document
    }
    
    public let mockResultData: [Query.BaseResultData]
}
