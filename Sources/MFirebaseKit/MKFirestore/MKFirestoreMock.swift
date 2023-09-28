//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift


public class MKFirestoreMock: MKFirestore {
    public enum AutoResponse {
        case success
        case error(MKFirestoreError)
    }
    var pendingPermutations: [MKPendingPermutation] = []
    var pendingDocumentQueries: [Any] = []
    var pendingCollectionQueries: [Any] = []
    var autoResponse: AutoResponse?
    
    public init(autoResponse: AutoResponse? = nil) {
        self.autoResponse = autoResponse
    }
    
    // MARK: - Document Query
    
    public func executePermutation(_ permutation: MKFirestorePermutation) async -> MKFirestorePermutationResponse {
        print("$ MKFirestoreMock: Executing Permutation with path \(permutation.firestoreReference.rawPath)")
        
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Permutation for path \(permutation.firestoreReference.rawPath)")
                return MKFirestorePermutationResponse(
                    documentId: permutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : permutation.firestoreReference.leafId,
                    error: nil)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Permutation for path \(permutation.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                return MKFirestorePermutationResponse(documentId: nil, error: error)
            }
        }
        
        let pendingPermutation = MKPendingPermutation(path: permutation.firestoreReference.rawPath, permutation: permutation)
        self.pendingPermutations.append(pendingPermutation)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                pendingPermutation.responseHandler = { error in
                    if let error {
                        continuation.resume(returning: MKFirestorePermutationResponse(
                            documentId: nil,
                            error: error))
                    } else {
                        continuation.resume(returning: MKFirestorePermutationResponse(
                            documentId: permutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : permutation.firestoreReference.leafId,
                            error: nil))
                    }
                }
            }
        } catch {
            return MKFirestorePermutationResponse(
                documentId: nil,
                error: .firestoreError(FirestoreErrorCode(FirestoreErrorCode.unknown)))
        }
    }
    
    public func executePermutation(_ permutation: MKFirestorePermutation, completion: @escaping (MKFirestorePermutationResponse) -> Void) {
        let path = permutation.firestoreReference.rawPath
        print("$ MKFirestoreMock: Executing Permutation with path \(path)")
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Permutation for path \(permutation.firestoreReference.rawPath)")
                let response = MKFirestorePermutationResponse(
                    documentId: permutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : permutation.firestoreReference.leafId,
                    error: nil)
                completion(response)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Permutation for path \(permutation.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                let response = MKFirestorePermutationResponse(documentId: nil, error: error)
                completion(response)
            }
            return
        }
        let pendingPermutation = MKPendingPermutation(path: path, permutation: permutation, responseHandler: { error in
            if let error {
                let response = MKFirestorePermutationResponse(
                    documentId: nil,
                    error: error)
                completion(response)
            } else {
                let response = MKFirestorePermutationResponse(
                    documentId: permutation.firestoreReference is MKFirestoreCollectionReference ? "NEW-DOCUMENT-ID" : permutation.firestoreReference.leafId,
                    error: nil)
                completion(response)
            }
        })
        pendingPermutations.append(pendingPermutation)
    }
    
    public func executeQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        print("$ MKFirestoreMock: Executing Query with path \(query.firestoreReference.rawPath)")
        let pendingQuery = MKPendingQuery(path: query.firestoreReference.rawPath, query: query)
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
            return MKFirestoreQueryResponse(error: .firestoreError(.init(FirestoreErrorCode.unknown)), responseData: nil)
        }
    }
    
    public func executeQuery<T: MKFirestoreQuery>(_ query: T, completion: @escaping (MKFirestoreQueryResponse<T>) -> Void) {
        let path = query.firestoreReference.rawPath
        print("$ MKFirestoreMock: Executing Query with path \(path)")
        if let response = makeAutoResponseIfNeeded(to: query, autoResponse: autoResponse) {
            completion(response)
        }
        let pendingQuery = MKPendingQuery<T>(path: path, query: query, responseHandler: completion)
        pendingDocumentQueries.append(pendingQuery as Any)
    }
    
    
    // MARK: - Respond Document
    public func respond(to permutation: MKFirestorePermutation, with error: FirestoreErrorCode.Code?) {
        if let pendingPermutation = pendingPermutations.first(where: { $0.path == permutation.firestoreReference.rawPath }) {
            var firestoreError: MKFirestoreError? = nil
            if let error {
                firestoreError = .firestoreError(FirestoreErrorCode(error))
            }
            if let firestoreError {
                print("$ MKFirestoreMock: Finished Permutation for path \(permutation.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(firestoreError.localizedDescription)")
            } else {
                print("$ MKFirestoreMock: Successfully finished Permutation for path \(permutation.firestoreReference.rawPath)")
            }
            pendingPermutation.responseHandler?(firestoreError)
        }
    }
    
    public func respond<T: MKFirestoreQuery>(to query: T, with error: FirestoreErrorCode.Code) {
        let response = MKFirestoreQueryResponse<T>(error: .firestoreError(FirestoreErrorCode(error)), responseData: nil)
        respond(to: query, with: response)
    }
    
    public func respond<T: MKFirestoreQuery>(to query: T, with data: T.ResultData) {
        let response = MKFirestoreQueryResponse<T>(error: nil, responseData: data)
        respond(to: query, with: response)
    }
    
    private func respond<T: MKFirestoreQuery>(to query: T, with response: MKFirestoreQueryResponse<T>) {
        let pendingQueries = pendingDocumentQueries.compactMap({ $0 as? MKPendingQuery<T> })
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
    
    private func makeAutoResponseIfNeeded<T: MKFirestoreQuery>(to query: T, autoResponse: AutoResponse?) -> MKFirestoreQueryResponse<T>? {
        if let autoResponse {
            switch autoResponse {
            case .success:
                print("$ MKFirestoreMock: Successfully finished Query for path \(query.firestoreReference.rawPath)")
                return MKFirestoreQueryResponse(error: nil, responseData: query.mockResultData)
            case .error(let error):
                print("$ MKFirestoreMock: Finished Query for path \(query.firestoreReference.rawPath) with error")
                print("$ MKFirestoreMock: \(error.localizedDescription)")
                return MKFirestoreQueryResponse(error: error, responseData: nil)
            }
        }
        return nil
    }
}

// MARK: - Helper

class MKPendingPermutation {
    typealias ResponseHander = (MKFirestoreError?)->Void
    
    let path: String
    let permutation: MKFirestorePermutation
    var responseHandler: ResponseHander?
    
    init(path: String, permutation: MKFirestorePermutation, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.permutation = permutation
        self.responseHandler = responseHandler
    }
}

class MKPendingQuery<T: MKFirestoreQuery> {
    typealias ResponseHander = (MKFirestoreQueryResponse<T>)->Void
    
    let path: String
    let query: T
    var responseHandler: ResponseHander?
    
    init(path: String, query: T, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.query = query
        self.responseHandler = responseHandler
    }
}
