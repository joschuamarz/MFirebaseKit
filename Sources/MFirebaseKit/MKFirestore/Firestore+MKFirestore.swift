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
        if query.firestorePath.isCollection {
            return await executeCollectionQuery(query)
        } else {
            return await executeDocumentQuery(query)
        }
    }
    
    public func executeQuery<T>(_ query: T, completion: @escaping (MKFirestoreQueryResponse<T>) -> Void) where T : MKFirestoreQuery {
        Task {
            if query.firestorePath.isCollection {
                let response = await executeCollectionQuery(query)
                completion(response)
            } else {
                let response = await executeDocumentQuery(query)
                completion(response)
            }
        }
    }
    
    
   
    
    private func executeDocumentQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        let documentReference = self.document(query.firestorePath.rawPath)
        print("$ MKFirestoreMock: Executing document Query with path \(query.firestorePath.rawPath)")
        do {
            let document = try await documentReference.getDocument()
            print(document)
            let result = try document.data(as: T.ResultData.self)
            return MKFirestoreQueryResponse(error: nil, responseData: result)
        } catch (let error) {
            if let firestoreError = error as? FirebaseFirestore.FirestoreErrorCode {
                return MKFirestoreQueryResponse<T>(error: .firestoreError(firestoreError), responseData: nil)
            } else {
                return MKFirestoreQueryResponse<T>(error: .parsingError(error), responseData: nil)
            }
        }
    }
    
    private func executeCollectionQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        let collectionReference = self.collection(query.firestorePath.rawPath)
        print("$ MKFirestoreMock: Executing document Query with path \(query.firestorePath.rawPath)")
        do {
            let documents = try await collectionReference.getDocuments().documents
            // Create a dictionary to store the JSON representation
            let jsonArray: [[String: Any]] = documents.map({ $0.data() })
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            let results = try JSONDecoder().decode(T.ResultData.self, from: jsonData)
            return MKFirestoreQueryResponse(error: nil, responseData: results)
        } catch (let error) {
            if let firestoreError = error as? FirebaseFirestore.FirestoreErrorCode {
                return MKFirestoreQueryResponse<T>(error: .firestoreError(firestoreError), responseData: nil)
            } else {
                return MKFirestoreQueryResponse<T>(error: .parsingError(error), responseData: nil)
            }
        }
    }
}
