//
//  File.swift
//  
//
//  Created by Joschua Marz on 27.09.23.
//

import Foundation

/// A base class representing a Firestore reference, such as a document or collection.
///
/// Use this class and its subclasses to represent and navigate Firestore paths.
public class MKFirestoreReference {
    
    /// The full raw Firestore path represented by this reference (e.g., `"users/user1"`).
    public let rawPath: String
    
    /// Initializes a Firestore reference with the given raw path.
    ///
    /// - Parameter rawPath: The Firestore path to initialize the reference with.
    init(rawPath: String) {
        self.rawPath = rawPath
    }
    
    /// Creates a reference to a top-level Firestore collection.
    ///
    /// - Parameter name: The name of the collection.
    /// - Returns: A `MKFirestoreCollectionReference` instance for the specified collection.
    public static func collection(_ name: String) -> MKFirestoreCollectionReference {
        return MKFirestoreCollectionReference(rawPath: name)
    }
    
    /// The last component of the path, typically the ID of the document or collection.
    ///
    /// For example, in `"users/user1"`, the `leafId` would be `"user1"`.
    public var leafId: String? {
        return rawPath.components(separatedBy: "/").last
    }
    
    /// The path to the nearest parent collection in the Firestore hierarchy.
    ///
    /// Subclasses override this to provide correct logic based on reference type.
    public var leafCollectionPath: String {
        ""
    }
}


/// A Firestore reference that points to a collection.
///
/// Use this class to navigate from a collection to its documents.
public class MKFirestoreCollectionReference: MKFirestoreReference {
    
    /// Returns a reference to a document within this collection.
    ///
    /// - Parameter documentId: The document ID.
    /// - Returns: A `MKFirestoreDocumentReference` instance representing the document.
    public func document(_ documentId: String) -> MKFirestoreDocumentReference {
        return MKFirestoreDocumentReference(rawPath: rawPath + "/" + documentId)
    }
    
    /// The full path of the collection this reference points to.
    public override var leafCollectionPath: String {
        return rawPath
    }
}

/// A Firestore reference that points to a document.
///
/// Use this class to navigate from a document to its subcollections.
public class MKFirestoreDocumentReference: MKFirestoreReference {
    
    /// Returns a reference to a subcollection within this document.
    ///
    /// - Parameter collectionName: The name of the subcollection.
    /// - Returns: A `MKFirestoreCollectionReference` instance representing the subcollection.
    public func collection(_ collectionName: String) -> MKFirestoreCollectionReference {
        return MKFirestoreCollectionReference(rawPath: rawPath + "/" + collectionName)
    }
    
    /// The path of the parent collection to which this document belongs.
    ///
    /// For example, if this reference points to `"users/user1"`, the `leafCollectionPath` would be `"users"`.
    public override var leafCollectionPath: String {
        var path = rawPath.components(separatedBy: "/")
        guard path.count >= 2 else { return "" }
        // Remove the document ID
        path.removeLast()
        return path.joined(separator: "/")
    }
}
