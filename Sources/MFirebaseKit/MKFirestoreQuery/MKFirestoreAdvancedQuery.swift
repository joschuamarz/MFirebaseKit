//
//  File.swift
//  
//
//  Created by Joschua Marz on 27.09.23.
//

import FirebaseFirestore

public protocol MKAFirestoreAdvancedQuery: MKFirestoreQuery {
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
    /// Apply a set of filters to the query. An empty array stand for no filters
    var filters: [MKFirestoreQueryFilter] { get }
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

extension Query {
    func applyFilter(_ filter: MKFirestoreQueryFilter) -> Query {
        switch filter {
        case .valueIn(let fieldName, let array):
            return self.whereField(fieldName, in: array)
        case .valueNotIn(let fieldName, let array):
            return self.whereField(fieldName, notIn: array)
        case .stringStartsWith(let fieldName, let prefix):
            return self.whereField(fieldName, isGreaterThanOrEqualTo: prefix)
                .whereField(fieldName, isLessThanOrEqualTo: prefix + "z")
        case .arrayContains(let fieldName, let value):
            return self.whereField(fieldName, arrayContains: value)
        case .isEqualTo(let fieldName, let value):
            return self.whereField(fieldName, isEqualTo: value)
        case .isNotEqualTo(let fieldName, let value):
            return self.whereField(fieldName, isNotEqualTo: value)
        case .isLessThan(let fieldName, let value):
            return self.whereField(fieldName, isLessThan: value)
        case .isLessThanOrEqualTo(let fieldName, let value):
            return self.whereField(fieldName, isLessThanOrEqualTo: value)
        case .isGreaterThan(let fieldName, let value):
            return self.whereField(fieldName, isGreaterThan: value)
        case .isGreaterThanOrEqualTo(let fieldName, let value):
            return self.whereField(fieldName, isGreaterThanOrEqualTo: value)
        case .arrayContaninsAny(let fieldName, let array):
            return self.whereField(fieldName, arrayContains: array)
        }
    }
}
