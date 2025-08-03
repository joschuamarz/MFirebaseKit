//
//  MKFirestoreMockData.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 01.08.25.
//


public struct MKFirestoreMockData {
    public let firestoreReference: MKFirestoreCollectionReference
    public let data: [String: Any]
    
    public init(firestoreReference: MKFirestoreCollectionReference, data: [String: any Codable & Identifiable]) {
        self.firestoreReference = firestoreReference
        self.data = data as [String: Any]
    }
}