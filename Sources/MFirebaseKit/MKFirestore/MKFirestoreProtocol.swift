//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import Foundation
import FirebaseFirestore

public protocol MKFirestore {
    func executeMutation(_ mutation: MKFirestoreDocumentMutation) async -> MKFirestoreMutationResponse
    func executeMutation(_ mutation: MKFirestoreDocumentMutation, completion: @escaping (MKFirestoreMutationResponse)->Void)
    func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T) async -> MKFirestoreDocumentQueryResponse<T>
    func executeDocumentQuery<T: MKFirestoreDocumentQuery>(_ query: T, completion: @escaping (MKFirestoreDocumentQueryResponse<T>)->Void)
    func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T) async -> MKFirestoreCollectionQueryResponse<T>
    func executeCollectionQuery<T: MKFirestoreCollectionQuery>(_ query: T, completion: @escaping (MKFirestoreCollectionQueryResponse<T>)->Void)
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
