//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation
import MFirebaseKitCore
import FirebaseFirestore
import FirebaseFirestoreSwift


extension DocumentChange: MKDocumentChange {
    public var changeType: MFirebaseKitCore.MKDocumentChangeType {
        switch self.type {
        case .added: return .added
        case .modified: return .modified
        case .removed: return .removed
        }
    }
    
    public func object<T: Decodable>(as type: T.Type) throws -> T {
        return try document.data(as: type.self)
    }
}
