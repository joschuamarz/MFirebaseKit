//
//  MKFirestoreSubcollectionService.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 02.08.25.
//

import Foundation
import Combine

class MKFirestoreSubcollectionService<BaseResultType: Codable & Identifiable>: MKObservableService {
    
    let firestore: MKFirestore
    let baseCollectionReference: MKFirestoreCollectionReference
    let subcollectionName: String
    
    public init(
        firestore: MKFirestore,
        baseCollectionReference: MKFirestoreCollectionReference,
        subcollectionName: String
    ) {
        self.firestore = firestore
        self.baseCollectionReference = baseCollectionReference
        self.subcollectionName = subcollectionName
    }
    
    @Published var documentIdToSubcollectionMap: [String: [BaseResultType]] = [:]
    
    public func getSubcollection(for documentId: String) -> [BaseResultType]? {
        return documentIdToSubcollectionMap[documentId]
    }
    
    public func loadSubcollection(for documentId: String) {
        // Define query for subcollection of given document
        let query = SubcollectionQuery(
            baseCollectionReference: baseCollectionReference,
            documentId: documentId,
            subcollectionName: subcollectionName
        )
        // asynchronously load subcollection results
        Task {
            if let results = await firestore.execute(query).responseData {
                // Write results on main thread
                await MainActor.run {
                    self.documentIdToSubcollectionMap[documentId] = results
                }
            }
        }
    }
}

extension MKFirestoreSubcollectionService {
    struct SubcollectionQuery: MKFirestoreCollectionQuery {
        var collectionReference: MKFirestoreCollectionReference
        
        init(
            baseCollectionReference: MKFirestoreCollectionReference,
            documentId: String,
            subcollectionName: String
        ) {
            self.collectionReference = baseCollectionReference
                .document(documentId)
                .collection(subcollectionName)
        }
        
        var filters: [MKFirestoreQueryFilter] = []
        var mockResultData: [BaseResultType] = []
        var orderDescriptor: OrderDescriptor? = nil
        var limit: Int? = nil
    }
}
