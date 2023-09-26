//
//  File.swift
//  
//
//  Created by Joschua Marz on 22.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

public protocol MKCollectionQuery {
    associatedtype ResultData: Codable
    var collection: MKFirestoreCollection { get }
    var mockResult: [ResultData] { get }
}

struct MKCollectionQueryResponse<Query: MKCollectionQuery> {
    let error: FirestoreErrorCode?
    let responseData: [Query.ResultData]?
    
    init(errorCode: FirestoreErrorCode.Code?, responseData: [Query.ResultData]?) {
        self.responseData = responseData
        if let errorCode {
            self.error = FirestoreErrorCode(errorCode)
        } else {
            self.error = nil
        }
    }
}


public protocol MKDocumentQuery {
    associatedtype ResultData: Codable
    var document: MKFirestoreDocument { get }
    var mockResult: ResultData { get }
}

struct MKDocumentQueryResponse<Query: MKDocumentQuery> {
    let error: FirestoreErrorCode?
    let responseData: Query.ResultData?
    
    init(errorCode: FirestoreErrorCode.Code?, responseData: Query.ResultData?) {
        self.responseData = responseData
        if let errorCode {
            self.error = FirestoreErrorCode(errorCode)
        } else {
            self.error = nil
        }
    }
}


