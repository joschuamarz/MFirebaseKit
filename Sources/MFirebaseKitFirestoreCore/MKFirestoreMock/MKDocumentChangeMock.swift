//
//  MKDocumentChangeMock.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 01.08.25.
//


struct MKDocumentChangeMock: MKDocumentChange {
    let changeType: MKDocumentChangeType
    let object: Any
    let documentID: String
    
    func object<T>(as type: T.Type) throws -> T where T : Decodable {
        guard let object = object as? T else {
            throw MKFirestoreError.internalError("MKDocumentChangeMock: Object does not match expected type \(type)")
        }
        return object
    }
}
