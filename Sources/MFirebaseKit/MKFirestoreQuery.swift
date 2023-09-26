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
    
    public static func collectionPath(_ path: String) -> MKFirestorePath {
        return MKFirestorePath(path: path, isCollection: true)
    }

    public static func documentPath(_ path: String) -> MKFirestorePath {
        return MKFirestorePath(path: path, isCollection: false)
    }
}

public struct MKFirestoreQueryResponse<Query: MKFirestoreQuery> {
    public let error: MKFirestoreError?
    public let responseData: Query.ResultData?
    
    init(error: MKFirestoreError?, responseData: Query.ResultData?) {
        self.responseData = responseData
        self.error = error
    }
}



