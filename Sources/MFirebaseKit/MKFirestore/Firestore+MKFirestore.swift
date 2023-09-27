//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

@available(macOS 10.15, *)
extension Firestore: MKFirestore {
    
    public func executeQuery<T>(_ query: T) async -> MKFirestoreQueryResponse<T> where T : MKFirestoreQuery {
        if query.firestoreReference is MKFirestoreCollectionReference {
            return await executeCollectionQuery(query)
        } else {
            return await executeDocumentQuery(query)
        }
    }
    
    public func executeQuery<T>(_ query: T, completion: @escaping (MKFirestoreQueryResponse<T>) -> Void) where T : MKFirestoreQuery {
        Task {
            if query.firestoreReference is MKFirestoreCollectionReference {
                let response = await executeCollectionQuery(query)
                completion(response)
            } else {
                let response = await executeDocumentQuery(query)
                completion(response)
            }
        }
    }
    
    private func executeDocumentQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        let documentReference = self.document(query.firestoreReference.rawPath)
        print("$ MKFirestore: Executing document Query with path \(query.firestoreReference.rawPath)")
        do {
            let document = try await documentReference.getDocument()
            let result = try document.data(as: T.ResultData.self)
            print("$ MKFirestore: Successfully finished document Query for path \(query.firestoreReference.rawPath)")
            return MKFirestoreQueryResponse(error: nil, responseData: result)
        } catch (let error) {
            return handleError(error, for: query)
        }
    }
    
    private func executeCollectionQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        let collectionReference = self.collection(query.firestoreReference.rawPath)
        var firestoreQuery: Query?
        if let query = query as? (any MKAdvancedFirestoreQuery) {
            // Order
            firestoreQuery = collectionReference.order(by: query.orderByFieldName, descending: query.orderDescending)
            // Filter
            for filter in query.filters {
                firestoreQuery = firestoreQuery?.applyFilter(filter)
            }
            // Start After
            if let startAfterFieldName = query.startAfterFieldValue {
                firestoreQuery = firestoreQuery?.start(after: [startAfterFieldName])
            }
            // Limit
            firestoreQuery = firestoreQuery?.limit(to: query.limit)
        }
        print("$ MKFirestore: Executing collection Query with path \(query.firestoreReference.rawPath)")
        do {
            let documents: [QueryDocumentSnapshot]
            if let firestoreQuery {
                documents = try await firestoreQuery.getDocuments().documents
            } else {
                documents = try await collectionReference.getDocuments().documents
            }
            let jsonArray: [[String: Any]] = documents.map({ $0.data() })
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            let results = try JSONDecoder().decode(T.ResultData.self, from: jsonData)
            print("$ MKFirestore: Successfully finished document Query for path \(query.firestoreReference.rawPath)")
            print("$ MKFirestore: Fetched \(jsonArray.count) objects")
            return MKFirestoreQueryResponse(error: nil, responseData: results)
        } catch (let error) {
            return handleError(error, for: query)
        }
    }
    
    private func handleError<T: MKFirestoreQuery>(_ error: Error, for query: T) -> MKFirestoreQueryResponse<T> {
        print("$ MKFirestore: Finished collection Query for path \(query.firestoreReference.rawPath) with Error")
        var specificError: MKFirestoreError
        if let firestoreError = error as? FirebaseFirestore.FirestoreErrorCode {
            specificError = .firestoreError(firestoreError)
        } else {
            specificError = .parsingError(error)
        }
        print("$ MKFirestore: \(specificError.localizedDescription)")
        return MKFirestoreQueryResponse<T>(error: specificError, responseData: nil)
    }
}
