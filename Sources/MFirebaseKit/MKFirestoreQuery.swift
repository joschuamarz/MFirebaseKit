//
//  File.swift
//  
//
//  Created by Joschua Marz on 22.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

enum MKFirestoreError {
    case firestoreError(FirestoreErrorCode)
    case parsingError(Error)
}

public protocol MKFirestoreQuery {
    associatedtype ResultData: Codable
    
    var firestorePath: MKFirestorePath { get }
    var mockResultData: ResultData { get }
}


public class MKFirestorePath {
    var rawPath: String
    var isCollection: Bool
    
    init(path: String, isCollection: Bool) {
        self.rawPath = path
        self.isCollection = isCollection
    }
    
    static func collectionPath(_ path: String) -> MKFirestorePath {
        return MKFirestorePath(path: path, isCollection: true)
    }
    static func documentPath(_ path: String) -> MKFirestorePath {
        return MKFirestorePath(path: path, isCollection: false)
    }
}

struct MKFirestoreQueryResponse<Query: MKFirestoreQuery> {
    let error: MKFirestoreError?
    let responseData: Query.ResultData?
    
    init(error: MKFirestoreError?, responseData: Query.ResultData?) {
        self.responseData = responseData
        self.error = error
    }
}



