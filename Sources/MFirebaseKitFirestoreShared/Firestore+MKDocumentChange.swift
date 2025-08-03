//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation
import MFirebaseKitFirestoreCore
import FirebaseFirestore


extension DocumentChange: @retroactive MKDocumentChange {
    public var changeType: MKDocumentChangeType {
        switch self.type {
        case .added: return .added
        case .modified: return .modified
        case .removed: return .removed
        }
    }

    public var documentID: String {
        document.documentID
    }

    public func object<T: Decodable>(as type: T.Type) throws -> T {
        return try document.data(as: type.self)
    }
}
