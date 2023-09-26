//
//  File.swift
//  
//
//  Created by Joschua Marz on 24.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

public class MKFirestoreCollection {
    var parentDocument: MKFirestoreDocument?
    var childDocument: MKFirestoreDocument?
    let collectionName: String
    
    public init(_ collectionName: String) {
        self.collectionName = collectionName
        self.parentDocument = nil
        self.childDocument = nil
    }
    
    init(_ collectionName: String, parentDocument: MKFirestoreDocument? = nil, childDocument: MKFirestoreDocument? = nil) {
        self.collectionName = collectionName
        self.parentDocument = parentDocument
        self.childDocument = childDocument
    }
    
    public func document(_ documentId: String) -> MKFirestoreDocument {
        let document =  MKFirestoreDocument(documentId: documentId, parentCollection: self)
        self.childDocument = document
        return document
    }

    func path() -> String {
        let path = collectionName
        if let parentDocument {
            return parentDocument.addPathPrefix(to: path)
        }
        return path
    }
    
    func addPathPrefix(to path: String) -> String {
        let path = "\(collectionName)/\(path)"
        if let parentDocument {
            return parentDocument.addPathPrefix(to: path)
        }
        return path
    }
}
