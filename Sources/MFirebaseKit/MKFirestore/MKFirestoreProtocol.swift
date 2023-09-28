//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import Foundation
import FirebaseFirestore

public protocol MKFirestore {
    func executePermutation(_ permutation: MKFirestorePermutation) async -> MKFirestorePermutationResponse
    func executePermutation(_ permutation: MKFirestorePermutation, completion: @escaping (MKFirestorePermutationResponse)->Void)
    func executeQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T>
    func executeQuery<T: MKFirestoreQuery>(_ query: T, completion: @escaping (MKFirestoreQueryResponse<T>)->Void)
}

public struct MKPaginatedQuery<Query: MKFirestoreQuery>: MKFirestoreQuery {
    public typealias ResultData = Query.ResultData
    
    public let firestoreReference: MKFirestoreReference
    public let mockResultData: Query.ResultData
    let limit: Int
    let lastDocument: DocumentSnapshot?
    
    init(query: Query, limit: Int, startAfter document: DocumentSnapshot?) {
        self.firestoreReference = query.firestoreReference
        self.mockResultData = query.mockResultData
        self.limit = limit
        self.lastDocument = document
    }
}
