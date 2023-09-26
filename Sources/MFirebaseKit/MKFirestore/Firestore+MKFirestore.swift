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
    func executeDocumentQuery<T>(_ query: T) async -> MKDocumentQueryResponse<T> where T : MKDocumentQuery {
        let documentReference = self.document(query.document.path())
        do {
            let document = try await documentReference.getDocument()
            let result = try document.data(as: T.ResultData.self)
            return MKDocumentQueryResponse(errorCode: nil, responseData: result)
        } catch (let error) {
            return MKDocumentQueryResponse(
                errorCode: (error as? FirebaseFirestore.FirestoreErrorCode)?.code ?? .unknown,
                responseData: nil)
        }
    }
    
    func executeDocumentQuery<T>(_ query: T, completion: @escaping (MKDocumentQueryResponse<T>) -> Void) where T : MKDocumentQuery {
        
    }
    
    func executeCollectionQuery<T: MKCollectionQuery>(_ query: T) async -> MKCollectionQueryResponse<T> {
        let collectionReference = self.collection(query.collection.path())
        do {
            var results: [T.ResultData] = []
            let documents = try await collectionReference.getDocuments().documents
            for document in documents {
                let result = try document.data(as: T.ResultData.self)
                results.append(result)
            }
            return MKCollectionQueryResponse(errorCode: nil, responseData: results)
        } catch (let error) {
            return MKCollectionQueryResponse(
                errorCode: (error as? FirebaseFirestore.FirestoreErrorCode)?.code ?? .unknown,
                responseData: nil)
        }
    }
  
    func executeCollectionQuery<T>(_ query: T, completion: @escaping (MKCollectionQueryResponse<T>) -> Void) where T : MKCollectionQuery {
        Task {
            let response = await executeCollectionQuery(query)
            completion(response)
        }
    }
}
