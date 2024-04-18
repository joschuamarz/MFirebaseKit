//
//  File.swift
//  
//
//  Created by Joschua Marz on 28.09.23.
//

import Foundation
import FirebaseFirestore

/// Mutation that changes data on Firestore document
///
/// - `firestoreReference`: Referencing either a `Document` or a `Collection`
/// - `operation`: The operation that should be executed.
///
/// > Info: If referencing a document, the changes will be executed on this document.
///   If referencing a collection, the changes will be executed on a newly created
///   document with an auto-generated `DocumentID`
public protocol MKFirestoreDocumentMutation: MKFirestoreQuery {
    /// Referencing either a `Document` or a `Collection`
    var firestoreReference: MKFirestoreReference { get }
    /// Operation that should be executed
    var operation: MKFirestoreMutationOperation { get }
}

extension MKFirestoreDocumentMutation {
    public var executionLogMessage: String {
        return "Executed DocumentMutation for \(self.firestoreReference)"
    }
}

/// Response of `MKFirestoreMutation`
///
/// - `documentId:` ID of the Document that was created / modified. Nil when an error occurred
/// - `error`: Optional `MKFirestoreError` providing more information if an error occurred
public struct MKFirestoreMutationResponse {
    /// ID of the Document that was created / modified. `nil` when an error occurred
    public let documentId: String?
    /// Optional `MKFirestoreError` providing more information if an error occurred
    public let error: MKFirestoreError?
}

extension MKFirestoreMutationResponse {
    var responseLogMessage: String {
        if let documentId {
            return "DocumentMutation succeeded with documentID \(documentId)"
        } else {
            return "DocumentMutation \(errorLogMessage(error ?? .firestoreError(FirestoreErrorCode(FirestoreErrorCode.internal))))"
        }
    }
    
    func errorLogMessage(_ error: MKFirestoreError) -> String {
        return "failed with error \(error.localizedDescription)"
    }
}
