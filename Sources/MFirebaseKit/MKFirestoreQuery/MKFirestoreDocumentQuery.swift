//
//  File.swift
//  
//
//  Created by Joschua Marz on 22.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

public protocol MKFirestoreOperation {
    var firestoreReference: MKFirestoreReference { get }
}

public protocol MKFirestoreDocumentQuery: MKFirestoreOperation {
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
}

public struct MKFirestoreDocumentQueryResponse<Query: MKFirestoreDocumentQuery> {
    public let error: MKFirestoreError?
    public let responseData: Query.ResultData?
    
    init(error: MKFirestoreError?, responseData: Query.ResultData?) {
        self.responseData = responseData
        self.error = error
    }
}
