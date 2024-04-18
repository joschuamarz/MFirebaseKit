//
//  File.swift
//  
//
//  Created by Joschua Marz on 16.11.23.
//

import Foundation

public protocol MKFirestoreDocumentDeletion: MKFirestoreQuery {
    var documentReference: MKFirestoreDocumentReference { get }
}

extension MKFirestoreDocumentDeletion {
    public var firestoreReference: MKFirestoreReference {
        return documentReference
    }
    
    public var executionLogMessage: String {
        return "Executed DocumentDeletion for \(self.firestoreReference.rawPath)"
    }
}
