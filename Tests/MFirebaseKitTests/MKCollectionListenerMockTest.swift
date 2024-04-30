//
//  MKCollectionListenerMockTest.swift
//  
//
//  Created by Joschua Marz on 05.03.24.
//

import XCTest
@testable import MFirebaseKit
import MFirebaseKitCore

final class MKCollectionListenerMockTest: XCTestCase {
    
    struct Meal: Codable, Identifiable {
        let id: String
        let name: String
        
        static let mocks: [Meal] = [
            .init(id: "1", name: "Cake"),
            .init(id: "2", name: "Fries"),
            .init(id: "3", name: "Potatos"),
            .init(id: "4", name: "Burger"),
        ]
    }
    
    struct MealDeletion: MKFirestoreDocumentDeletion {
        var documentReference: MKFirestoreDocumentReference
        
        init(id: String) {
            documentReference = .collection("test").document(id)
        }
    }
    
    struct MealMutation: MKFirestoreDocumentMutation {
        var firestoreReference: MKFirestoreReference
        
        var operation: MKFirestoreMutationOperation
        
        init(meal: Meal) {
            self.firestoreReference = .collection("test").document(meal.id)
            self.operation = .setData(from: meal, merge: true)
        }
    }
    
    struct GetMealsQuery: MKFirestoreCollectionQuery {
        typealias BaseResultData = Meal
        
        var collectionReference: MKFirestoreCollectionReference = .collection("test")
        
        var mockResultData: [MKCollectionListenerMockTest.Meal] = []
        
        var orderDescriptor: OrderDescriptor? = nil
        
        var limit: Int? = nil
        
        var filters: [MKFirestoreQueryFilter]
        
        init(name: String) {
            filters = [.isEqualTo("name", name)]
        }
        
        init(id: String) {
            filters = [.isEqualTo("id", id)]
        }
        
        init() {
            filters = []
        }
        
    }
    
    func testListenerSetup() {
        let firestore = MKFirestoreListenerMock<Meal>(objects: Meal.mocks)
        let listener = MKFirestoreCollectionListener(query: GetMealsQuery(name: "Burger"), firestore: firestore)
        listener.startListening()
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertEqual(listener.objects.first?.name, "Burger")
    }
    
    func testListenerModification() {
        let firestore = MKFirestoreListenerMock<Meal>(objects: Meal.mocks)
        let listener = MKFirestoreCollectionListener(query: GetMealsQuery(), firestore: firestore)
        listener.startListening()
        XCTAssertEqual(listener.objects.count, 4)
        XCTAssertTrue(listener.objects.contains(where: { $0.name == "Burger"}))
        
        // Delete
        _ = firestore.executeDeletion(MealDeletion(id: "4"))
        XCTAssertEqual(listener.objects.count, 3)
        XCTAssertFalse(listener.objects.contains(where: { $0.name == "Burger"}))
        
        // Add
        _ = firestore.executeMutation(MealMutation(meal: .init(id: "8", name: "Test")))
        XCTAssertEqual(listener.objects.count, 4)
        XCTAssertTrue(listener.objects.contains(where: { $0.name == "Test"}))
        
        // Modify
        _ = firestore.executeMutation(MealMutation(meal: .init(id: "8", name: "Test New")))
        XCTAssertEqual(listener.objects.count, 4)
        XCTAssertFalse(listener.objects.contains(where: { $0.name == "Test"}))
        XCTAssertTrue(listener.objects.contains(where: { $0.name == "Test New"}))
    }

}

