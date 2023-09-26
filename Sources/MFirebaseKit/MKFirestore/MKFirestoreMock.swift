//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift


public class FirestoreMock: MKFirestore {
    var pendingDocumentQueries: [Any] = []
    var pendingCollectionQueries: [Any] = []
    var autoRespond: Bool
    
    public init(autoRespond: Bool = false) {
        self.autoRespond = autoRespond
    }
    
    // MARK: - Document Query
    
    public func executeQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        print("$ MKFirestoreMock: Executing document Query with path \(query.firestorePath.rawPath)")
        let pendingQuery = MKPendingQuery(path: query.firestorePath.rawPath, query: query)
        guard !autoRespond else {
            return MKFirestoreQueryResponse(error: nil, responseData: query.mockResultData)
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
        let path = query.firestorePath.rawPath
        print("$ MKFirestoreMock: Executing document Query with path \(path)")
        guard !autoRespond else {
            completion(MKFirestoreQueryResponse(error: nil, responseData: query.mockResultData))
            return
        }
        let pendingQuery = MKPendingQuery<T>(path: path, query: query, responseHandler: completion)
        pendingDocumentQueries.append(pendingQuery as Any)
    }
    
    
    // MARK: - Respond Document
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
        if let pendingQuery = pendingQueries.first(where: { $0.path == query.firestorePath.rawPath }) {
            pendingQuery.responseHandler?(response)
        }
    }
    
}

// MARK: - Helper

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
