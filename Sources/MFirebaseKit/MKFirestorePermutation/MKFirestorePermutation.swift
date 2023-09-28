//
//  File.swift
//  
//
//  Created by Joschua Marz on 28.09.23.
//

import Foundation
import FirebaseFirestore

public struct MKFirestoreFieldPermutation {
    var data: [String: Any]
    
    public static func increment(fieldName: String, by x: Double) -> MKFirestoreFieldPermutation {
        return MKFirestoreFieldPermutation(data: [fieldName: FieldValue.increment(x)])
    }
    
    public static func update(fieldName: String, with value: Any) -> MKFirestoreFieldPermutation {
        return MKFirestoreFieldPermutation(data: [fieldName: value])
    }
}

public struct MKFirestorePermutationOperation {
    var data: [String: Any]?
    var object: Encodable?
    var merge: Bool
    
    public static func updateFields(_ fieldPermutations: [MKFirestoreFieldPermutation], merge: Bool) -> MKFirestorePermutationOperation {
        var dataSet: [String:Any] = [:]
        for data in fieldPermutations.map({ $0.data }) {
            for (key, value) in data {
                dataSet.updateValue(value, forKey: key)
            }
        }
        return MKFirestorePermutationOperation(data:dataSet, merge: merge)
    }
    
    public static func addDocument(_ data: [String: Any]) -> MKFirestorePermutationOperation {
        return .setData(data, merge: true)
    }
    
    public static func setData(_ data: [String: Any], merge: Bool) -> MKFirestorePermutationOperation {
        return MKFirestorePermutationOperation(data: data, merge: merge)
    }
    
    public static func addDocument(from object: Encodable) -> MKFirestorePermutationOperation {
        return .setData(from: object, merge: true)
    }
    
    public static func setData(from object: Encodable, merge: Bool) -> MKFirestorePermutationOperation {
        return MKFirestorePermutationOperation(object: object, merge: merge)
    }
}


public protocol MKFirestorePermutation: MKFirestoreOperation {
    var firestoreReference: MKFirestoreReference { get }
    var operation: MKFirestorePermutationOperation { get }
}

public struct MKFirestorePermutationResponse {
    let documentId: String?
    let error: MKFirestoreError?
}
