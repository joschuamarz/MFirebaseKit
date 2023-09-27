//
//  File.swift
//  
//
//  Created by Joschua Marz on 27.09.23.
//

import FirebaseFirestore

public enum MKFirestoreError {
    case firestoreError(FirestoreErrorCode)
    case parsingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .firestoreError(let error):
            switch error.code {
            case .cancelled: return "The operation was canceled."
            case .unknown: return "An unknown error occurred."
            case  .invalidArgument: return "An invalid argument was provided."
            case .deadlineExceeded: return "The operation timed out."
            case .notFound: return "The requested document or resource was not found."
            case .permissionDenied: return "The user does not have permission to perform the operation."
            case .unauthenticated: return "The user is not authenticated."
            case .resourceExhausted: return "Resource limits were exceeded."
            case .failedPrecondition: return "A precondition for the operation was not met."
            case .aborted:  return "The operation was aborted."
            case .outOfRange: return "An index is out of range."
            case .unimplemented: return "The requested operation is not implemented."
            case .internal: return "An internal Firestore error occurred."
            case .unavailable: return "The service is unavailable."
            case .dataLoss: return "Data was lost during the operation."
            default: return error.localizedDescription
            }
        case .parsingError(let error):
            return error.localizedDescription
        }
    }
}
