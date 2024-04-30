//
//  File.swift
//  
//
//  Created by Joschua Marz on 05.03.24.
//

import Foundation

public class MKFirestoreListenerMock<BaseResultType: Codable & Identifiable>: MKFirestore {
    private var objects: [BaseResultType] = [] {
        didSet {
            changeHandler?(objects)
        }
    }
    private var changeHandler: (([BaseResultType])->Void)?
    public init(objects: [BaseResultType]) {
        self.objects = objects
    }
    
    public func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T : MKFirestoreCollectionQuery {
        
        if T.BaseResultData.self == BaseResultType.self {
            let results = objects.applyFilters(query.filters) as? [T.BaseResultData]
            return .init(error: nil, responseData: results)
        }
        return .init(error: .internalError("MKFirestoreListenerMock"), responseData: nil)
    }
    
    public func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T : MKFirestoreDocumentQuery {
        if T.ResultData.self == BaseResultType.self, let id = query.documentReference.leafId {
            if let result = objects.applyFilters([.isEqualTo("id", id)]).first as? T.ResultData {
                return .init(error: nil, responseData: result)
            }
        }
        return .init(error: .internalError("MKFirestoreListenerMock"), responseData: nil)
    }
    
    public func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
        if let id = deletion.documentReference.leafId {
            if let result = objects.applyFilters([.isEqualTo("id", id)]).first,
               let index = objects.firstIndex(where: { $0.id == result.id }) {
                objects.remove(at: index)
                return nil
            }
        }
        return .internalError("MKFirestoreListenerMock")
    }
    
    public func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
        guard let object = mutation.operation.object as? BaseResultType else {
            return .init(documentId: nil, error: .internalError("MKFirestoreListenerMock"))
        }
        if let id = mutation.firestoreReference.leafId {
            if let result = objects.applyFilters([.isEqualTo("id", id)]).first,
               let index = objects.firstIndex(where: { $0.id == result.id }) {
                objects[index] = object
                return .init(documentId: "\(object.id)", error: nil)
            } else if let object = mutation.operation.object as? BaseResultType {
                objects.append(object)
            }
        }
        return .init(documentId: nil, error: .internalError("MKFirestoreListenerMock"))
    }
    
    public func addCollectionListener<T>(_ listener: MKFirestoreCollectionListener<T>) -> MKListenerRegistration where T : MKFirestoreCollectionQuery {
        self.changeHandler = { objects in
            if let objects = objects as? [T.BaseResultData] {
                listener.objects = objects
            }
        }
        if T.BaseResultData.self == BaseResultType.self {
            if let results = objects.applyFilters(listener.query.filters) as? [T.BaseResultData] {
                listener.objects = results
            }
        }
        return MockListenerRegistration { [weak self] in
            // self?.activeListeners.removeAll(where: { $0 == listenerId })
        }
    }
}


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
