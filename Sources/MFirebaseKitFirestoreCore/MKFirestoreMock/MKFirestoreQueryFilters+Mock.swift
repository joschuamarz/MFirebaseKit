//
//  MKFirestoreQueryFilters+Mock.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 03.08.25.
//

import Foundation

extension Array {
    func applyFilters(_ filters: [MKFirestoreQueryFilter]) -> Self {
        var modifiedArray = self
        for filter in filters {
            switch filter {
            case .valueIn( _,_):
                continue
            case .valueNotIn( _,_):
                continue
            case .stringStartsWith( _,_):
                continue
            case .arrayContains( _,_):
                continue
            case .isEqualTo(let name, let value):
                modifiedArray = modifiedArray.filter({ isEqualTo($0, name, value)})
            case .isNotEqualTo(let name, let value):
                modifiedArray = modifiedArray.filter({ isNotEqualTo($0, name, value)})
            case .isLessThan(let name, let value):
                modifiedArray = modifiedArray.filter({ isLessThan($0, name, value)})
            case .isLessThanOrEqualTo(let name, let value):
                modifiedArray = modifiedArray.filter({ isLessThan($0, name, value)})
            case .isGreaterThan(let name, let value):
                modifiedArray = modifiedArray.filter({ isMoreThan($0, name, value)})
            case .isGreaterThanOrEqualTo(let name, let value):
                modifiedArray = modifiedArray.filter({ isMoreThan($0, name, value)})
            case .arrayContaninsAny( _,_):
                continue
            }
        }
        return modifiedArray
    }
    
    mutating func removeAllMatching(fieldName: String, value: Any) {
        let filteredItems = self.filter { !isEqualTo($0, fieldName, value) }
        self = filteredItems
    }
    
    func firstIndexMatching(fieldName: String, value: Any) -> Int? {
        return self.firstIndex(where: { isEqualTo($0, fieldName, value)})
    }
    
    func isEqualTo(_ object: Any, _ fieldName: String, _ value: Any) -> Bool {
        let mirror = Mirror(reflecting: object)
        
        if fieldName == "id", let object = object as? (any Identifiable), isAny(object.id, equalTo: value) {
            return true
        }
        
        for (name, propVal) in mirror.children {
            if let propertyName = name, propertyName == fieldName {
                return isAny(propVal, equalTo: value)
            }
        }
        
        return false
    }
    
    func isNotEqualTo(_ object: Any, _ fieldName: String, _ value: Any) -> Bool {
        let mirror = Mirror(reflecting: object)
        
        for (name, propVal) in mirror.children {
            if let propertyName = name, propertyName == fieldName {
                return !isAny(propVal, equalTo: value)
            }
        }
        
        return false
    }
    
    func isLessThan(_ object: Any, _ fieldName: String, _ value: Any) -> Bool {
        let mirror = Mirror(reflecting: object)
        
        for (name, propVal) in mirror.children {
            if let propertyName = name, propertyName == fieldName {
                return isAny(propVal, lessThan: value)
            }
        }
        
        return false
    }
    
    func isMoreThan(_ object: Any, _ fieldName: String, _ value: Any) -> Bool {
        let mirror = Mirror(reflecting: object)
        
        for (name, propVal) in mirror.children {
            if let propertyName = name, propertyName == fieldName {
                return isAny(propVal, greaterThan: value)
            }
        }
        
        return false
    }
    
    func isAny(_ a: Any, equalTo b: Any) -> Bool {
        if let a = a as? String, let b = b as? String {
            return a == b
        }
        
        if let a = a as? Int, let b = b as? Int {
            return a == b
        }
        
        if let a = a as? Float, let b = b as? Float {
            return a == b
        }
        
        if let a = a as? Double, let b = b as? Double {
            return a == b
        }
        
        if let a = a as? Date, let b = b as? Date {
            return a == b
        }
        return false
    }
    
    func isAny(_ a: Any, lessThan b: Any) -> Bool {
        if let a = a as? Int, let b = b as? Int {
            return a < b
        }
        
        if let a = a as? Float, let b = b as? Float {
            return a < b
        }
        
        if let a = a as? Double, let b = b as? Double {
            return a < b
        }
        
        if let a = a as? Date, let b = b as? Date {
            return a < b
        }
        return false
    }
    
    func isAny(_ a: Any, greaterThan b: Any) -> Bool {
        if let a = a as? Int, let b = b as? Int {
            return a > b
        }
        
        if let a = a as? Float, let b = b as? Float {
            return a > b
        }
        
        if let a = a as? Double, let b = b as? Double {
            return a > b
        }
        
        if let a = a as? Date, let b = b as? Date {
            return a > b
        }
        return false
    }
}
