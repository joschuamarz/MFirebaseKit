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
    /// Reference to the Document or Collection
    var firestoreReference: MKFirestoreReference { get }
    /// Provide a result that can be used for `FirestoreMock
    var mockResultData: ResultData { get }
}

public protocol MKAdvancedFirestoreQuery: MKFirestoreQuery {
    /// The name of the field that should be used for ordering the data
    var orderByFieldName: String { get }
    /// Boolean value if the data should be ordered descending
    var orderDescending: Bool { get }
    /// Define the value after which the query should start
    /// *! IMPORTANT !*
    /// The value must be for the same field as the sorting (`oderByFieldName`)
    var startAfterFieldValue: Any? { get }
    /// Maximum number of results for this query
    var limit: Int { get }
    /// 
    var filters: [MKFirestoreQueryFilter] { get }
}


public struct MKFirestoreQueryFilter {
    
    enum Predicate {
        case valueIn([Any])
        case valueNotIn([Any])
        case stringStartsWith(String)
        case arrayContains(Any)
        case isEqualTo(Any)
        case isNotEqualTo(Any)
        case isLessThan(Any)
        case isLessThanOrEqualTo(Any)
        case isGreaterThan(Any)
        case isGreaterThanOrEqualTo(Any)
        case arrayContaninsAny([Any])
    }

    let fieldName: String
    let predicate: Predicate
    
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


extension Query {
    func applyFilter(_ filter: MKFirestoreQueryFilter) -> Query {
        switch filter.predicate {
        case .valueIn(let array):
            return self.whereField(filter.fieldName, in: array)
        case .valueNotIn(let array):
            return self.whereField(filter.fieldName, notIn: array)
        case .stringStartsWith(let prefix):
            return self.whereField(filter.fieldName, isGreaterThanOrEqualTo: prefix)
                .whereField(filter.fieldName, isLessThanOrEqualTo: prefix + "z")
        case .arrayContains(let value):
            return self.whereField(filter.fieldName, arrayContains: value)
        case .isEqualTo(let value):
            return self.whereField(filter.fieldName, isEqualTo: value)
        case .isNotEqualTo(let value):
            return self.whereField(filter.fieldName, isNotEqualTo: value)
        case .isLessThan(let value):
            return self.whereField(filter.fieldName, isLessThan: value)
        case .isLessThanOrEqualTo(let value):
            return self.whereField(filter.fieldName, isLessThanOrEqualTo: value)
        case .isGreaterThan(let value):
            return self.whereField(filter.fieldName, isGreaterThan: value)
        case .isGreaterThanOrEqualTo(let value):
            return self.whereField(filter.fieldName, isGreaterThanOrEqualTo: value)
        case .arrayContaninsAny(let array):
            return self.whereField(filter.fieldName, arrayContains: array)
        }
    }
}
