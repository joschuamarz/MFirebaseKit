//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation
import MFirebaseKitFirestoreCore
import FirebaseFirestore

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
