//
//  File.swift
//  
//
//  Created by Joschua Marz on 27.09.23.
//

import Foundation

public protocol MKFirestoreCollectionQuery: MKFirestoreQuery {
    /// Use the base type of the array.
    /// If your Query should return `[Int]`, you should put `Int` here
    associatedtype BaseResultData: Codable & Identifiable
    
    var collectionReference: MKFirestoreCollectionReference { get }
    /// Provide a result that can be used for `FirestoreMock
    var mockResultData: [BaseResultData] { get }
    /// Describe how to order the query
    var orderDescriptor: OrderDescriptor? { get }
    /// Maximum number of results for this query
    var limit: Int? { get }
    /// Apply a set of filters to the query. An empty array stand for no filters
    var filters: [MKFirestoreQueryFilter] { get }
}

extension MKFirestoreCollectionQuery {
    var id: String {
        return collectionReference.rawPath
        + "-\(orderDescriptor.debugDescription)"
        + "-\(limit.debugDescription)"
        + "-\(filters.debugDescription)"
    }
    
    func isEqual(to otherQuery: any MKFirestoreCollectionQuery) -> Bool {
        print(id)
        print(otherQuery.id)
        return id == otherQuery.id
    }
}


public struct OrderDescriptor {
    /// The name of the field that should be used for ordering the data
    public var orderByFieldName: String
    /// Boolean value if the data should be ordered descending
    public var orderDescending: Bool
    /// Define the value after which the query should start
    ///
    ///  - Warning: *IMPORTANT!*
    /// The value must be for the same field as the sorting (`oderByFieldName`)
    /// e.g. Sort by `count` - start after `20`
    public var startAfterFieldValue: Any?
    
    public init(orderByFieldName: String, orderDescending: Bool, startAfterFieldValue: Any? = nil) {
        self.orderByFieldName = orderByFieldName
        self.orderDescending = orderDescending
        self.startAfterFieldValue = startAfterFieldValue
    }
}

extension MKFirestoreCollectionQuery {
    public var firestoreReference: MKFirestoreReference {
        return collectionReference
    }
    
    public var executionLogMessage: String {
        return "Executed CollectionQuery for \(self.firestoreReference.rawPath)"
    }
}

public struct MKFirestoreCollectionQueryResponse<Query: MKFirestoreCollectionQuery> {
    public let error: MKFirestoreError?
    public let responseData: [Query.BaseResultData]?
    
    public init(error: MKFirestoreError?, responseData: [Query.BaseResultData]?) {
        self.responseData = responseData
        self.error = error
    }
}

extension MKFirestoreCollectionQueryResponse {
    public var responseLogMessage: String {
        if let responseData {
            return "CollectionQuery succeeded with \(responseData.count) results"
        } else {
            return "CollectionQuery \(errorLogMessage(error ?? .internalError("CollectionQuery")))"
        }
    }
    
    func errorLogMessage(_ error: MKFirestoreError) -> String {
        return "failed with error \(error.localizedDescription)"
    }
}

public enum MKFirestoreQueryFilter {
    
    case valueIn(_ fieldName: String, _ array: [Any])
    case valueNotIn(_ fieldName: String, _ array: [Any])
    case stringStartsWith(_ fieldName: String, _ prefix: String)
    case arrayContains(_ fieldName: String, _ value: Any)
    case isEqualTo(_ fieldName: String, _ value: Any)
    case isNotEqualTo(_ fieldName: String, _ value: Any)
    case isLessThan(_ fieldName: String, _ value: Any)
    case isLessThanOrEqualTo(_ fieldName: String, _ value: Any)
    case isGreaterThan(_ fieldName: String, _ value: Any)
    case isGreaterThanOrEqualTo(_ fieldName: String, _ value: Any)
    case arrayContaninsAny(_ fieldName: String, _ array: [Any])
    
    public static func whereField(_ fieldName: String, in array: [Any]) -> MKFirestoreQueryFilter {
        return .valueIn(fieldName, array)
    }
    
    public static func whereField(_ fieldName: String, notIn array: [Any]) -> MKFirestoreQueryFilter {
        return .valueNotIn(fieldName, array)
    }
    
    public static func whereField(_ fieldName: String, startWith prefix: String) -> MKFirestoreQueryFilter {
        return .stringStartsWith(fieldName, prefix)
    }
    
    public static func whereField(_ fieldName: String, arrayContains value: Any) -> MKFirestoreQueryFilter {
        return .arrayContains(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, isEqualTo value: Any) -> MKFirestoreQueryFilter {
        return .isEqualTo(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, isNotEqualTo value: Any) -> MKFirestoreQueryFilter {
        return .isNotEqualTo(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, isLessThan value: Any) -> MKFirestoreQueryFilter {
        return .isLessThan(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, isLessThanOrEqualTo value: Any) -> MKFirestoreQueryFilter {
        return .isLessThanOrEqualTo(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, isGreaterThan value: Any) -> MKFirestoreQueryFilter {
        return .isGreaterThan(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, isGreaterThanOrEqualTo value: Any) -> MKFirestoreQueryFilter {
        return .isGreaterThanOrEqualTo(fieldName, value)
    }
    
    public static func whereField(_ fieldName: String, arrayContainsAny array: [Any]) -> MKFirestoreQueryFilter {
        return .arrayContaninsAny(fieldName, array)
    }
}

