//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//


import Foundation

public class MKFirestoreMock: MKFirestore {
    
    private var activeListeners: [String] = []
    
    private func mockChanges<T: MKFirestoreCollectionQuery>(for listener: MKFirestoreCollectionListener<T>, with id: String) {
        guard listener.query.mockResultData.count > 0 else { return }
    
        Task {
            try? await Task.sleep(nanoseconds: 1000000000)
            
            for mock in listener.query.mockResultData {
//                listener.onAdded(mock, listener.query)
            }
            
            guard listenerMockMode == .auto else { return }
            
            while activeListeners.contains(id) {
                var mocks = listener.query.mockResultData
                let last = mocks.removeLast()
                // remove
                try? await Task.sleep(nanoseconds: 1000000000)
//                listener.onRemoved(last, listener.query)
                
                try? await Task.sleep(nanoseconds: 1000000000)
                let secondLast = mocks.removeLast()
//                listener.onRemoved(secondLast, listener.query)
                
                try? await Task.sleep(nanoseconds: 1000000000)
//                listener.onAdded(secondLast, listener.query)
                
                try? await Task.sleep(nanoseconds: 1000000000)
//                listener.onAdded(last, listener.query)
            }
        }
        
    }
    
    public func addCollectionListener<T: MKFirestoreCollectionQuery>(_ listener: MKFirestoreCollectionListener<T>) -> MKListenerRegistration {
        let listenerId: String = UUID().uuidString
        activeListeners.append(listenerId)
        if listenerMockMode != .none {
            mockChanges(for: listener, with: listenerId)
        }
        return MockListenerRegistration { [weak self] in
            self?.activeListeners.removeAll(where: { $0 == listenerId })
        }
    }
    
    public func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) async -> MKFirestoreError? {
        return nil
    }
    
    public enum AutoResponse {
        case success
        case error(MKFirestoreError)
    }
    
    public enum ListenerMockMode {
        case none, initial, auto
    }
    var pendingMutations: [MKPendingMutation] = []
    var pendingDocumentQueries: [Any] = []
    var pendingCollectionQueries: [Any] = []
    var autoResponse: AutoResponse?
    var listenerMockMode: ListenerMockMode
    
    public init(autoResponse: AutoResponse? = nil, listenerMockMode: ListenerMockMode = .none) {
        self.autoResponse = autoResponse
        self.listenerMockMode = listenerMockMode
    }
    
    // MARK: - Document Query
    
    public func executeMutation(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse {
        print("$ MKFirestoreMock: Executing Mutation with path \(mutation.firestoreReference.rawPath)")
        
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Mutation for path \(mutation.firestoreReference.rawPath)")
                return MKFirestoreMutationResponse(
                    documentId: mutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : mutation.firestoreReference.leafId,
                    error: nil)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Mutation for path \(mutation.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                return MKFirestoreMutationResponse(documentId: nil, error: error)
            }
        }
        
        let pendingMutation = MKPendingMutation(path: mutation.firestoreReference.rawPath, mutation: mutation)
        self.pendingMutations.append(pendingMutation)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                pendingMutation.responseHandler = { error in
                    if let error {
                        continuation.resume(returning: MKFirestoreMutationResponse(
                            documentId: nil,
                            error: error))
                    } else {
                        continuation.resume(returning: MKFirestoreMutationResponse(
                            documentId: mutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : mutation.firestoreReference.leafId,
                            error: nil))
                    }
                }
            }
        } catch {
            return MKFirestoreMutationResponse(
                documentId: nil,
                error: .internalError("FirestoreMock"))
        }
    }
    
    public func executeMutation(_ mutation: MKFirestoreDocumentMutation, completion: @escaping (MKFirestoreMutationResponse) -> Void) {
        let path = mutation.firestoreReference.rawPath
        print("$ MKFirestoreMock: Executing Mutation with path \(path)")
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Mutation for path \(mutation.firestoreReference.rawPath)")
                let response = MKFirestoreMutationResponse(
                    documentId: mutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : mutation.firestoreReference.leafId,
                    error: nil)
                completion(response)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Mutation for path \(mutation.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                let response = MKFirestoreMutationResponse(documentId: nil, error: error)
                completion(response)
            }
            return
        }
        let pendingMutation = MKPendingMutation(path: path, mutation: mutation, responseHandler: { error in
            if let error {
                let response = MKFirestoreMutationResponse(
                    documentId: nil,
                    error: error)
                completion(response)
            } else {
                let response = MKFirestoreMutationResponse(
                    documentId: mutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : mutation.firestoreReference.leafId,
                    error: nil)
                completion(response)
            }
        })
        pendingMutations.append(pendingMutation)
    }
    
    // MARK: -  Document Query
    public func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T) async -> MKFirestoreDocumentQueryResponse<T> {
        print("$ MKFirestoreMock: Executing Query with path \(query.firestoreReference.rawPath)")
        let pendingQuery = MKPendingDocumentQuery(path: query.firestoreReference.rawPath, query: query)
        if let response = makeAutoResponseIfNeeded(to: query, autoResponse: autoResponse) {
            return response
        }
        pendingDocumentQueries.append(pendingQuery as Any)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                pendingQuery.responseHandler = { response in
                    continuation.resume(returning: response)
                }
            }
        } catch {
            return MKFirestoreDocumentQueryResponse(error: .internalError("FirestoreMock"), responseData: nil)
        }
    }
    
    public func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T, completion: @escaping (MKFirestoreDocumentQueryResponse<T>) -> Void) {
        let path = query.firestoreReference.rawPath
        print("$ MKFirestoreMock: Executing Query with path \(path)")
        if let response = makeAutoResponseIfNeeded(to: query, autoResponse: autoResponse) {
            completion(response)
        }
        let pendingQuery = MKPendingDocumentQuery<T>(path: path, query: query, responseHandler: completion)
        pendingDocumentQueries.append(pendingQuery as Any)
    }
    
    // MARK: -  Collection Query
    
    public func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T) async -> MKFirestoreCollectionQueryResponse<T> {
        print("$ MKFirestoreMock: Executing Query with path \(query.firestoreReference.rawPath)")
        let pendingQuery = MKPendingCollectionQuery(path: query.firestoreReference.rawPath, query: query)
        if let response = makeAutoResponseIfNeeded(to: query, autoResponse: autoResponse) {
            return response
        }
        pendingDocumentQueries.append(pendingQuery as Any)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                pendingQuery.responseHandler = { response in
                    continuation.resume(returning: response)
                }
            }
        } catch {
            return MKFirestoreCollectionQueryResponse(error: .internalError("FirestoreMock"), responseData: nil)
        }
    }
    
    public func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T, completion: @escaping (MKFirestoreCollectionQueryResponse<T>) -> Void) {
        let path = query.firestoreReference.rawPath
        print("$ MKFirestoreMock: Executing Query with path \(path)")
        if let response = makeAutoResponseIfNeeded(to: query, autoResponse: autoResponse) {
            completion(response)
        }
        let pendingQuery = MKPendingCollectionQuery<T>(path: path, query: query, responseHandler: completion)
        pendingDocumentQueries.append(pendingQuery as Any)
    }
    
    
    // MARK: - Respond Document
    public func respond(to mutation: MKFirestoreDocumentMutation, with error: MKFirestoreError?) {
        if let pendingMutation = pendingMutations.first(where: { $0.path == mutation.firestoreReference.rawPath }) {
            if let error {
                print("$ MKFirestoreMock: Finished Mutation for path \(mutation.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
            } else {
                print("$ MKFirestoreMock: Successfully finished Mutation for path \(mutation.firestoreReference.rawPath)")
            }
            pendingMutation.responseHandler?(error)
        }
    }
    
    public func respond<T: MKFirestoreDocumentQuery>(to query: T, with error: MKFirestoreError) {
        let response = MKFirestoreDocumentQueryResponse<T>(error: error, responseData: nil)
        respond(to: query, with: response)
    }
    
    public func respond<T: MKFirestoreDocumentQuery>(to query: T, with data: T.ResultData) {
        let response = MKFirestoreDocumentQueryResponse<T>(error: nil, responseData: data)
        respond(to: query, with: response)
    }
    
    private func respond<T: MKFirestoreDocumentQuery>(to query: T, with response: MKFirestoreDocumentQueryResponse<T>) {
        let pendingQueries = pendingDocumentQueries.compactMap({ $0 as? MKPendingDocumentQuery<T> })
        if let pendingQuery = pendingQueries.first(where: { $0.path == query.firestoreReference.rawPath }) {
            if let error = response.error {
                print("$ MKFirestoreMock: Finished Query for path \(query.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
            } else {
                print("$ MKFirestoreMock: Successfully finished Query for path \(query.firestoreReference.rawPath)")
            }
            pendingQuery.responseHandler?(response)
        }
    }
    
    public func respond<T: MKFirestoreCollectionQuery>(to query: T, with error: MKFirestoreError) {
        let response = MKFirestoreCollectionQueryResponse<T>(error: error, responseData: nil)
        respond(to: query, with: response)
    }
    
    public func respond<T: MKFirestoreCollectionQuery>(to query: T, with data: [T.BaseResultData]) {
        let response = MKFirestoreCollectionQueryResponse<T>(error: nil, responseData: data)
        respond(to: query, with: response)
    }
    
    private func respond<T: MKFirestoreCollectionQuery>(to query: T, with response: MKFirestoreCollectionQueryResponse<T>) {
        let pendingQueries = pendingDocumentQueries.compactMap({ $0 as? MKPendingCollectionQuery<T> })
        if let pendingQuery = pendingQueries.first(where: { $0.path == query.firestoreReference.rawPath }) {
            if let error = response.error {
                print("$ MKFirestoreMock: Finished Query for path \(query.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
            } else {
                print("$ MKFirestoreMock: Successfully finished Query for path \(query.firestoreReference.rawPath)")
            }
            pendingQuery.responseHandler?(response)
        }
    }
    
    private func makeAutoResponseIfNeeded<T: MKFirestoreDocumentQuery>(to query: T, autoResponse: AutoResponse?) -> MKFirestoreDocumentQueryResponse<T>? {
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Query for path \(query.firestoreReference.rawPath)")
                return MKFirestoreDocumentQueryResponse(error: nil, responseData: query.mockResultData)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Query for path \(query.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                return MKFirestoreDocumentQueryResponse(error: error, responseData: nil)
            }
        }
        return nil
    }
    
    private func makeAutoResponseIfNeeded<T: MKFirestoreCollectionQuery>(to query: T, autoResponse: AutoResponse?) -> MKFirestoreCollectionQueryResponse<T>? {
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Query for path \(query.firestoreReference.rawPath)")
                return MKFirestoreCollectionQueryResponse(error: nil, responseData: query.mockResultData)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Query for path \(query.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                return MKFirestoreCollectionQueryResponse(error: error, responseData: nil)
            }
        }
        return nil
    }
}

// MARK: - Helper

class MKPendingMutation {
    typealias ResponseHander = (MKFirestoreError?)->Void
    
    let path: String
    let mutation: MKFirestoreDocumentMutation
    var responseHandler: ResponseHander?
    
    init(path: String, mutation: MKFirestoreDocumentMutation, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.mutation = mutation
        self.responseHandler = responseHandler
    }
}

class MKPendingDocumentQuery<T: MKFirestoreDocumentQuery> {
    typealias ResponseHander = (MKFirestoreDocumentQueryResponse<T>)->Void
    
    let path: String
    let query: T
    var responseHandler: ResponseHander?
    
    init(path: String, query: T, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.query = query
        self.responseHandler = responseHandler
    }
}

class MKPendingCollectionQuery<T: MKFirestoreCollectionQuery> {
    typealias ResponseHander = (MKFirestoreCollectionQueryResponse<T>)->Void
    
    let path: String
    let query: T
    var responseHandler: ResponseHander?
    
    init(path: String, query: T, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.query = query
        self.responseHandler = responseHandler
    }
}
