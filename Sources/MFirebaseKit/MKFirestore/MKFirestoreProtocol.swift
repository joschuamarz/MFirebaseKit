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

// MARK: - Default Implementations

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

// MARK: - Overloads
extension MKFirestore {
    // Queries
    public func execute<Q: MKFirestoreDocumentQuery>(_ query: Q) async -> MKFirestoreDocumentQueryResponse<Q> {
        return await executeDocumentQuery(query)
    }
    
    public func execute<Q: MKFirestoreDocumentQuery>(_ query: Q, completion: @escaping (MKFirestoreDocumentQueryResponse<Q>)->Void) {
        executeDocumentQuery(query, completion: completion)
    }
    
    public func execute<Q: MKFirestoreCollectionQuery>(_ query: Q) async -> MKFirestoreCollectionQueryResponse<Q> {
        return await executeCollectionQuery(query)
    }
    
    public func execute<Q: MKFirestoreCollectionQuery>(_ query: Q, completion: @escaping (MKFirestoreCollectionQueryResponse<Q>)->Void) {
        executeCollectionQuery(query, completion: completion)
    }
    
    // Mutations
    @discardableResult
    public func execute(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse {
        return await executeMutation(mutation)
    }
    
    func execute(_ mutation: MKFirestoreDocumentMutation, completion: @escaping (MKFirestoreMutationResponse)->Void) {
        executeMutation(mutation, completion: completion)
    }
    
    // Deletions
    func execute(_ deletion: MKFirestoreDocumentDeletion) {
        executeDeletion(deletion)
    }
    
    @discardableResult
    func execute(_ deletion: MKFirestoreDocumentDeletion) async -> MKFirestoreError? {
        return await executeDeletion(deletion)
    }
    
    func execute(_ deletion: MKFirestoreDocumentDeletion, completion: @escaping (MKFirestoreError?)->Void) {
        executeDeletion(deletion, completion: completion)
    }
}


