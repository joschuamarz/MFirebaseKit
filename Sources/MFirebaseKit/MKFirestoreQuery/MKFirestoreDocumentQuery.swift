//
//  File.swift
//  
//
//  Created by Joschua Marz on 22.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

public protocol MKFirestoreQuery {
    var firestoreReference: MKFirestoreReference { get }
    var executionLogMessage: String { get }
}

public protocol MKFirestoreDocumentQuery: MKFirestoreQuery {
    associatedtype ResultData: Codable
    /// Reference to the Document or Collection
    var documentReference: MKFirestoreDocumentReference { get }
    /// Provide a result that can be used for `FirestoreMock
    var mockResultData: ResultData { get }
}

extension MKFirestoreDocumentQuery {
    public var firestoreReference: MKFirestoreReference {
        return documentReference
    }
    
    public var executionLogMessage: String {
        return "Executed DocumentQuery for \(self.firestoreReference)"
    }
}

public struct MKFirestoreDocumentQueryResponse<Query: MKFirestoreDocumentQuery> {
    public let error: MKFirestoreError?
    public let responseData: Query.ResultData?
    
    init(error: MKFirestoreError?, responseData: Query.ResultData?) {
        self.responseData = responseData
        self.error = error
    }
}

extension MKFirestoreDocumentQueryResponse {
    public var responseLogMessage: String {
        if let responseData {
            return "DocumentQuery succeeded"
        } else {
            return "DocumentQuery \(errorLogMessage(error ?? .firestoreError(FirestoreErrorCode(FirestoreErrorCode.internal))))"
        }
    }
    
    func errorLogMessage(_ error: MKFirestoreError) -> String {
        return "failed with error \(error.localizedDescription)"
    }
}
