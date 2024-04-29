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
    
    var leafId: String? {
        return rawPath.components(separatedBy: "/").last
    }
    
    public var leafCollectionPath: String {
        ""
    }
}

public class MKFirestoreCollectionReference: MKFirestoreReference {
    public func document(_ documentId: String) -> MKFirestoreDocumentReference {
        return MKFirestoreDocumentReference(rawPath: rawPath + "/" + documentId)
    }
    
    override var leafCollectionPath: String {
        return rawPath
    }
}

public class MKFirestoreDocumentReference: MKFirestoreReference {
    public func collection(_ collectionName: String) -> MKFirestoreCollectionReference {
        return MKFirestoreCollectionReference(rawPath: rawPath + "/" + collectionName)
    }
    
    override var leafCollectionPath: String {
        var path = rawPath.components(separatedBy: "/")
        guard path.count >= 2 else { return "" }
        // remove document
        path.removeLast()
        
        return path.joined(separator: "/")
    }
}
