//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.04.24.
//

import Foundation
import XCTest
import MFirebaseKit
import MFirebaseKitDebug

final class MFirebaseKitDebugTest: XCTestCase {
    
    func test() {
        let recipes = [
            Recipe(name: "Test 1"),
            Recipe(name: "Test 2"),
            Recipe(name: "Test 3"),
        ]
        let mockData = MKFirestoreFullMockData(
            firestoreReference: .collection("Main").document("Test").collection("Recipes"),
            data: recipes
        )
        let firestore = MKFirestoreFullMock(mockData: [mockData])
        let listener = MKFirestoreCollectionListener(query: GetAllRecipes(), firestore: firestore)
        listener.startListening()
        XCTAssertEqual(listener.objects.count, 3)
        firestore.executeMutation(RecipeMutation(recipe: Recipe(name: "Test 4")))
        XCTAssertEqual(listener.objects.count, 4)
        listener.stopListening()
        XCTAssertEqual(listener.objects.count, 0)
        listener.startListening()
        XCTAssertEqual(listener.objects.count, 4)
    }
    
}

// MARK: - Recipe
extension MFirebaseKitDebugTest {
    struct Recipe: Codable, Identifiable {
        let id: String
        let name: String
        
        init(name: String) {
            self.init(id: UUID().uuidString, name: name)
        }
        
        init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }
}

// MARK: - Get All
extension MFirebaseKitDebugTest {
    struct GetAllRecipes: MKFirestoreCollectionQuery {
        typealias BaseResultData = Recipe
        
        var collectionReference: MKFirestoreCollectionReference = .collection("Main").document("Test").collection("Recipes")
        
        var orderDescriptor: MFirebaseKit.OrderDescriptor? = nil
        var limit: Int? = nil
        var filters: [MFirebaseKit.MKFirestoreQueryFilter] = []
        var mockResultData: [Recipe] = []
    }
}

// MARK: - Mutation
extension MFirebaseKitDebugTest {
    struct RecipeMutation: MKFirestoreDocumentMutation {
        var firestoreReference: MKFirestoreReference
        var operation: MKFirestoreMutationOperation
        
        init(recipe: Recipe) {
            self.firestoreReference = .collection("Main").document("Test").collection("Recipes")
            self.operation = .setData(from: recipe, merge: false)
        }
    }
}
