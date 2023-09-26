//
//  File.swift
//  
//
//  Created by Joschua Marz on 24.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

public class MKFirestoreDocument {
    var parentCollection: MKFirestoreCollection
    var childCollection: MKFirestoreCollection?
    let documentId: String
    
    init(documentId: String, parentCollection: MKFirestoreCollection, childCollection: MKFirestoreCollection? = nil) {
        self.documentId = documentId
        self.parentCollection = parentCollection
        self.childCollection = childCollection
    }
    
    public func collection(_ collectionName: String) -> MKFirestoreCollection {
        let collection = MKFirestoreCollection(collectionName, parentDocument: self)
        self.childCollection = collection
        return collection
    }
    
    func path() -> String {
        let path = documentId
        return parentCollection.addPathPrefix(to: path)
    }
    
    func addPathPrefix(to path: String) -> String {
        let path = "\(documentId)/\(path)"
        return parentCollection.addPathPrefix(to: path)
    }
}
