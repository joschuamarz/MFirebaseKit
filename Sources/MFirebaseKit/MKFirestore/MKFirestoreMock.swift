//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

@available(macOS 10.15, *)
class FirestoreMock: MKFirestore {
    var pendingDocumentQueries: [Any] = []
    var pendingCollectionQueries: [Any] = []
    
    // MARK: - Document Query
    
    func executeDocumentQuery<T>(_ query: T) async -> MKDocumentQueryResponse<T> where T : MKDocumentQuery {
        let path = query.document.path()
        print("$ MKFirestoreMock: Executing document Query with path \(path)")
        let pendingQuery = MKPendingDocumentQuery(path: path, query: query)
        pendingDocumentQueries.append(pendingQuery as Any)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                pendingQuery.responseHandler = { response in
                    continuation.resume(returning: response)
                }
            }
        } catch {
            return MKDocumentQueryResponse(errorCode: .unknown, responseData: nil)
        }
    }
    
    func executeDocumentQuery<T>(_ query: T, completion: @escaping (MKDocumentQueryResponse<T>) -> Void) where T : MKDocumentQuery {
        let path = query.document.path()
        print("$ MKFirestoreMock: Executing document Query with path \(path)")
        let pendingQuery = MKPendingDocumentQuery<T>(path: path, query: query, responseHandler: completion)
        pendingDocumentQueries.append(pendingQuery as Any)
    }
    
    // MARK: - Collection Query
    func executeCollectionQuery<T>(_ query: T) async -> MKCollectionQueryResponse<T> where T : MKCollectionQuery {
        let path = query.collection.path()
        print("$ MKFirestoreMock: Executing collection Query with path \(path)")
        let pendingQuery = MKPendingCollectionQuery<T>(path: path, query: query)
        pendingCollectionQueries.append(pendingQuery as Any)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                pendingQuery.responseHandler = { response in
                    continuation.resume(returning: response)
                }
            }
        } catch {
            return MKCollectionQueryResponse(errorCode: .unknown, responseData: nil)
        }
    }
    
    func executeCollectionQuery<T>(_ query: T, completion: @escaping (MKCollectionQueryResponse<T>)->Void)  where T: MKCollectionQuery , T.ResultData: Codable {
        let path = query.collection.path()
        print("$ MKFirestoreMock: Executing collection Query with path \(path)")
        let pendingQuery = MKPendingCollectionQuery<T>(path: path, query: query, responseHandler: completion)
        pendingCollectionQueries.append(pendingQuery as Any)
    }
    
    // MARK: - Respond Document
    public func respond<T: MKDocumentQuery>(to query: T, with errorCode: FirestoreErrorCode.Code) {
        let response = MKDocumentQueryResponse<T>(errorCode: errorCode, responseData: nil)
        respond(to: query, with: response)
    }
    
    public func respond<T: MKDocumentQuery>(to query: T, with data: T.ResultData) {
        let response = MKDocumentQueryResponse<T>(errorCode: nil, responseData: data)
        respond(to: query, with: response)
    }
    
    private func respond<T: MKDocumentQuery>(to query: T, with response: MKDocumentQueryResponse<T>) {
        let pendingQueries = pendingDocumentQueries.compactMap({ $0 as? MKPendingDocumentQuery<T> })
        if let pendingQuery = pendingQueries.first(where: { $0.path == query.document.path() }) {
            pendingQuery.responseHandler?(response)
        }
    }
    
    // MARK: - Respond Collection
    public func respond<T: MKCollectionQuery>(to query: T, with errorCode: FirestoreErrorCode.Code) {
        let response = MKCollectionQueryResponse<T>(errorCode: errorCode, responseData: nil)
        respond(to: query, with: response)
    }
    
    public func respond<T: MKCollectionQuery>(to query: T, with data: [T.ResultData]) {
        let response = MKCollectionQueryResponse<T>(errorCode: nil, responseData: data)
        respond(to: query, with: response)
    }
    
    private func respond<T: MKCollectionQuery>(to query: T, with response: MKCollectionQueryResponse<T>) {
        let pendingQueries = pendingCollectionQueries.compactMap({ $0 as? MKPendingCollectionQuery<T> })
        if let pendingQuery = pendingQueries.first(where: { $0.path == query.collection.path() }) {
            pendingQuery.responseHandler?(response)
        }
    }
}

// MARK: - Helper
class MKPendingCollectionQuery<T: MKCollectionQuery> {
    typealias ResponseHander = (MKCollectionQueryResponse<T>)->Void
    
    let path: String
    let query: T
    var responseHandler: ResponseHander?
    
    init(path: String, query: T, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.query = query
        self.responseHandler = responseHandler
    }
}

class MKPendingDocumentQuery<T: MKDocumentQuery> {
    typealias ResponseHander = (MKDocumentQueryResponse<T>)->Void
    
    let path: String
    let query: T
    var responseHandler: ResponseHander?
    
    init(path: String, query: T, responseHandler: ResponseHander? = nil) {
        self.path = path
        self.query = query
        self.responseHandler = responseHandler
    }
}
