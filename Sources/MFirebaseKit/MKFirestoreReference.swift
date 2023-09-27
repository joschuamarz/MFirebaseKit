//
//  File.swift
//  
//
//  Created by Joschua Marz on 27.09.23.
//

import Foundation

public class MKFirestoreReference {
    public let rawPath: String
    init(rawPath: String) {
        self.rawPath = rawPath
    }
    public static func collection(_ name: String) -> MKFirestoreCollectionReference {
        return MKFirestoreCollectionReference(rawPath: name)
    }
}

public class MKFirestoreCollectionReference: MKFirestoreReference {
    public func document(_ documentId: String) -> MKFirestoreDocumentReference {
        return MKFirestoreDocumentReference(rawPath: rawPath + "/" + documentId)
    }
}

public class MKFirestoreDocumentReference: MKFirestoreReference {
    public func collection(_ collectionName: String) -> MKFirestoreCollectionReference {
        return MKFirestoreCollectionReference(rawPath: rawPath + "/" + collectionName)
    }
}
