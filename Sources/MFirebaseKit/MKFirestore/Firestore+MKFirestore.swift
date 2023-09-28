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
    
    // MARK: - Mutations
    
    
    public func executeMutation(_ mutation: MKFirestoreMutation) async -> MKFirestoreMutationResponse {
        if mutation.firestoreReference is MKFirestoreCollectionReference {
            return await executeCollectionMutation(mutation)
        } else {
            return await executeDocumentMutation(mutation)
        }
    }
    
    public func executeMutation(_ mutation: MKFirestoreMutation, completion: @escaping (MKFirestoreMutationResponse) -> Void) {
        Task {
            if mutation.firestoreReference is MKFirestoreCollectionReference {
                let response = await executeCollectionMutation(mutation)
                completion(response)
            } else {
                let response = await executeDocumentMutation(mutation)
                completion(response)
            }
        }
    }
    
    private func executeCollectionMutation(_ mutation: MKFirestoreMutation) async -> MKFirestoreMutationResponse {
        do {
            if let data = mutation.operation.data {
                let documentId = try await self.collection(mutation.firestoreReference.rawPath).addDocument(data: data).documentID
                return MKFirestoreMutationResponse(documentId: documentId, error: nil)
            } else if let object = mutation.operation.object {
                let documentId = try self.collection(mutation.firestoreReference.rawPath).addDocument(from: object).documentID
                return MKFirestoreMutationResponse(documentId: documentId, error: nil)
            }
            return MKFirestoreMutationResponse(documentId: nil, error: .firestoreError(FirestoreErrorCode(FirestoreErrorCode.invalidArgument)))
        } catch (let error) {
            return MKFirestoreMutationResponse(documentId: nil, error: handleError(error, for: mutation))
        }
    }
    
    private func executeDocumentMutation(_ mutation: MKFirestoreMutation) async -> MKFirestoreMutationResponse {
        do {
            if let data = mutation.operation.data {
                try await self.document(mutation.firestoreReference.rawPath).setData(data, merge: mutation.operation.merge)
                return MKFirestoreMutationResponse(documentId: mutation.firestoreReference.leafId, error: nil)
            } else if let object = mutation.operation.object {
                try self.document(mutation.firestoreReference.rawPath).setData(from: object, merge: mutation.operation.merge)
                return MKFirestoreMutationResponse(documentId: mutation.firestoreReference.leafId, error: nil)
            }
            return MKFirestoreMutationResponse(documentId: nil, error: .firestoreError(FirestoreErrorCode(FirestoreErrorCode.invalidArgument)))
        } catch (let error) {
            return MKFirestoreMutationResponse(documentId: nil, error: handleError(error, for: mutation))
        }
    }
    
    // MARK: - Queries
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
            return MKFirestoreQueryResponse<T>(error: handleError(error, for: query), responseData: nil)
        }
    }
    
    private func executeCollectionQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T> {
        let collectionReference = self.collection(query.firestoreReference.rawPath)
        var firestoreQuery: Query?
        if let query = query as? (any MKFirestoreAdvancedQuery) {
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
            return MKFirestoreQueryResponse<T>(error: handleError(error, for: query), responseData: nil)
        }
    }
    
    // MARK: - Handle Error
    private func handleError<T: MKFirestoreOperation>(_ error: Error, for query: T) -> MKFirestoreError {
        print("$ MKFirestore: Finished collection Query for path \(query.firestoreReference.rawPath) with Error")
        var specificError: MKFirestoreError
        if let firestoreError = error as? FirebaseFirestore.FirestoreErrorCode {
            specificError = .firestoreError(firestoreError)
        } else {
            specificError = .parsingError(error)
        }
        print("$ MKFirestore: \(specificError.localizedDescription)")
        return specificError
    }
}
