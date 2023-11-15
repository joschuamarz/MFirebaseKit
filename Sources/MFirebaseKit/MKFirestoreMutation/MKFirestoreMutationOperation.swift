//
//  File.swift
//  
//
//  Created by Joschua Marz on 15.11.23.
//

import Foundation
import FirebaseFirestore

/// Mutating operation that can be executed both on collections and documents.
///
/// > Info: Executed on a document reference, this will update / set the data of the referenced document.
/// > Executed on a collection reference, this will create a new document with an auto-generated `DocumentID`.
public struct MKFirestoreMutationOperation {
    /// Data that should be uploaded
    var data: [String: Any]?
    /// Encodable object that should be uploaded
    var object: Encodable?
    /// Defines if the other fields of the document (if existing) should stay in place
    /// or if the document should be overwritten with **only** the provided fields.
    var merge: Bool
    
    
    // MARK: - Add Document
    
    /// Add a document containing the provided fields
    ///
    /// - Parameter data: Data that should be set for the new document
    ///
    /// > Info: Executed on a document reference, this will update / set the data of the referenced document.
    /// > Executed on a collection reference, this will create a new document with an auto-generated `DocumentID`.
    public static func addDocument(_ data: [String: Any]) -> MKFirestoreMutationOperation {
        return MKFirestoreMutationOperation(data: data, merge: true)
    }
    
    /// Add a document containing the data of the provided object
    ///
    /// - Parameter data: Data that should be set for the new document
    ///
    /// > Info: Executed on a document reference, this will update / set the data of the referenced document.
    /// > Executed on a collection reference, this will create a new document with an auto-generated `DocumentID`.
    public static func addDocument(from object: Encodable) -> MKFirestoreMutationOperation {
        return MKFirestoreMutationOperation(object: object, merge: true)
    }
    
    // MARK: - Set Data
    
    /// Sets the given data for a document
    ///
    /// - Parameter data: Data that should be set for the new document
    /// - Parameter merge: Defines if the other fields of the document (if existing) should stay in place
    ///   or if the document should be overwritten with **only** the provided fields.
    ///
    /// > Info: Executed on a document reference, this will update / set the data of the referenced document.
    /// > Executed on a collection reference, this will create a new document with an auto-generated `DocumentID`.
    ///
    /// > Warning: With `merge = false`, this will override all other fields of the document!
    public static func setData(_ data: [String: Any], merge: Bool) -> MKFirestoreMutationOperation {
        return MKFirestoreMutationOperation(data: data, merge: merge)
    }
    
    /// Sets the data of the given object for a document
    ///
    /// - Parameter object: The object that should be set for the new document
    /// - Parameter merge: Defines if the other fields of the document (if existing) should stay in place
    ///   or if the document should be overwritten with **only** the provided fields.
    ///
    /// > Info: Executed on a document reference, this will update / set the data of the referenced document.
    /// > Executed on a collection reference, this will create a new document with an auto-generated `DocumentID`.
    ///
    /// > Warning: With `merge = false`, this will override all other fields of the document!
    public static func setData(from object: Encodable, merge: Bool) -> MKFirestoreMutationOperation {
        return MKFirestoreMutationOperation(object: object, merge: merge)
    }
    
    // MARK: - Update Fields
    
    /// Update the a given set of fields by providing their new values.
    ///
    ///
    ///  - Parameter fieldMutations: An array of `MKFirestoreFieldMutation` that defines
    ///   the fields that should be updated as well as the new values.
    ///  - Parameter merge: Defines if the other fields of the document (if existing) should stay in place
    ///   or if the document should be overwritten with **only** the provided fields.
    ///
    /// > Info: Executed on a collection, this operation creates a new document
    /// > containing the provided fields and their new values!
    ///
    /// > Warning: With `merge = false`, this will override all other fields of the document!
    public static func updateFields(_ fieldMutations: [MKFirestoreFieldUpdate], merge: Bool) -> MKFirestoreMutationOperation {
        let data: [String: Any] = Dictionary(uniqueKeysWithValues: fieldMutations.map { ($0.fieldName, $0.newValue) })
        return MKFirestoreMutationOperation(data: data, merge: merge)
    }
}


/// Defines the update for a specific field. It can either increment/decrement
/// a numeric field value or assign a new value of any type.
///
/// > Info: If no field exists for the given `fieldName`, a new field will be created.
public struct MKFirestoreFieldUpdate {
    /// The name of the field that should be updated
    let fieldName: String
    /// The new value that should be assigned
    let newValue: Any
    
    /// Increment / decrement the numeric value of a field.
    ///
    /// - Parameter fieldName: Exact name of the field that should be updated.
    /// - Parameter x: Double value that should be added to the current (numeric) value of the field.
    ///   Positive `x` values will increment the field value while negative `x` values will decrement the field value.
    ///
    /// > Tip: Use positive values of x to increment a field value
    /// > and negative values to decrement.
    ///
    /// > Info: If no field exists for the given `fieldName`, a new field will be created.
    public static func increment(fieldName: String, by x: Double) -> MKFirestoreFieldUpdate {
        return MKFirestoreFieldUpdate(fieldName: fieldName, newValue: FieldValue.increment(x))
    }
    
    /// Set a new value for a given field
    ///
    /// - Parameter fieldName: Exact name of the field that should be updated.
    /// - Parameter value: The new value that should be assigned for the given field.
    ///
    /// > Info: If no field exists for the given `fieldName`, a new field will be created.
    public static func update(fieldName: String, with value: Any) -> MKFirestoreFieldUpdate {
        return MKFirestoreFieldUpdate(fieldName: fieldName, newValue: value)
    }
}
