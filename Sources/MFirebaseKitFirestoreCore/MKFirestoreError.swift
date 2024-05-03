//
//  File.swift
//  
//
//  Created by Joschua Marz on 27.09.23.
//

public enum MKFirestoreError {
    case firestoreError(String)
    case parsingError(Error)
    case internalError(String)

    public var localizedDescription: String {
        switch self {
        case .internalError(let description):
            return "InternalError at \(description)"
        case .firestoreError(let description):
            return "FirestoreError: \(description)"
        case .parsingError(let error):
            return error.localizedDescription
        }
    }
}
