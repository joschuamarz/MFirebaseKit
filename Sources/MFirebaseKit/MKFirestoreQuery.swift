//
//  File.swift
//  
//
//  Created by Joschua Marz on 22.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

public protocol MKFirestoreQuery {
    associatedtype ResultData: Codable
    
    var firestoreReference: MKFirestoreReference { get }
    var mockResultData: ResultData { get }
}

public protocol MKAdvancedQuery: MKFirestoreQuery {
    var orderByFieldName: String { get }
    var orderDescending: Bool { get }
    var startAfterFieldValue: Any? { get }
    var limit: Int { get }
}


struct Mock: Codable {
    let name: String
}

public struct MKFirestoreOrderDescriptor {
    let fieldName: String
    let descending: Bool = false
}

public struct MKFirestoreQueryResponse<Query: MKFirestoreQuery> {
    public let error: MKFirestoreError?
    public let responseData: Query.ResultData?
    
    init(error: MKFirestoreError?, responseData: Query.ResultData?) {
        self.responseData = responseData
        self.error = error
    }
}

public class MKFirestorePaginatedQuery<Query: MKFirestoreQuery>: MKFirestoreQuery {
    public typealias ResultData = Query.ResultData
    
    public var firestoreReference: MKFirestoreReference
    public var mockResultData: Query.ResultData
    var lastDocumentSnapshot: DocumentSnapshot?
    var limit: Int
    
    init(query: Query, limit: Int) {
        mockResultData = query.mockResultData
        firestoreReference = query.firestoreReference
        self.limit = limit
    }
}


