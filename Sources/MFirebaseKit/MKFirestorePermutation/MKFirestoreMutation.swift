//
//  File.swift
//  
//
//  Created by Joschua Marz on 28.09.23.
//

import Foundation
import FirebaseFirestore

public struct MKFirestoreFieldMutation {
    var data: [String: Any]
    
    public static func increment(fieldName: String, by x: Double) -> MKFirestoreFieldMutation {
        return MKFirestoreFieldMutation(data: [fieldName: FieldValue.increment(x)])
    }
    
    public static func update(fieldName: String, with value: Any) -> MKFirestoreFieldMutation {
        return MKFirestoreFieldMutation(data: [fieldName: value])
    }
}

public struct MKFirestoreMutationOperation {
    var data: [String: Any]?
    var object: Encodable?
    var merge: Bool
    
    public static func updateFields(_ fieldMutations: [MKFirestoreFieldMutation], merge: Bool) -> MKFirestoreMutationOperation {
        var dataSet: [String:Any] = [:]
        for data in fieldMutations.map({ $0.data }) {
            for (key, value) in data {
                dataSet.updateValue(value, forKey: key)
            }
        }
        return MKFirestoreMutationOperation(data:dataSet, merge: merge)
    }
    
    public static func addDocument(_ data: [String: Any]) -> MKFirestoreMutationOperation {
        return .setData(data, merge: true)
    }
    
    public static func setData(_ data: [String: Any], merge: Bool) -> MKFirestoreMutationOperation {
        return MKFirestoreMutationOperation(data: data, merge: merge)
    }
    
    public static func addDocument(from object: Encodable) -> MKFirestoreMutationOperation {
        return .setData(from: object, merge: true)
    }
    
    public static func setData(from object: Encodable, merge: Bool) -> MKFirestoreMutationOperation {
        return MKFirestoreMutationOperation(object: object, merge: merge)
    }
}


public protocol MKFirestoreMutation: MKFirestoreOperation {
    var firestoreReference: MKFirestoreReference { get }
    var operation: MKFirestoreMutationOperation { get }
}

public struct MKFirestoreMutationResponse {
    let documentId: String?
    let error: MKFirestoreError?
}
