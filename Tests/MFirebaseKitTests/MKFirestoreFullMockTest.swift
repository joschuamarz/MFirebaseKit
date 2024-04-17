//
//  MKFirestoreFullMockTest.swift
//  
//
//  Created by Joschua Marz on 12.04.24.
//

import XCTest
@testable import MFirebaseKitDebug
@testable import MFirebaseKit

final class MKFirestoreFullMockTest: XCTestCase {
    
    func testMutation() {
        let firestore = MKFirestoreFullMock()
        let recipe1 = Recipe(name: "Test 1")
        let recipe2 = Recipe(name: "Test 2")
        let recipe3 = Recipe(name: "Test 3")
        for recipe in [recipe1, recipe2, recipe3] {
            firestore.executeMutation(RecipeMutation(recipe: recipe))
        }
        let objects = firestore.executeCollectionQuery(GetAllRecipes()).responseData
        XCTAssertEqual(objects?.count, 3)
    }
    
    func testAsyncMutation() async {
        let expectation = MKFirestoreExpectation(
            firestoreReference: .collection("Main").document("Test").collection("Recipes"),
            type: .query
        )
        let recipes = [
            Recipe(name: "Test 1"),
            Recipe(name: "Test 2"),
            Recipe(name: "Test 3"),
        ]
        let mockData = MKFirestoreFullMockData(
            firestoreReference: .collection("Main").document("Test").collection("Recipes"),
            data: recipes
        )
        let firestore = MKFirestoreFullMockDebug(mockData: [mockData], expectations: [expectation])
        let sut = AsyncGetRecipesHelper(firestore: firestore)
        sut.executeQuery()
        XCTAssertEqual(sut.recipes.count, 0)
        await fulfillment(of: [expectation])
        XCTAssertEqual(sut.recipes.count, 3)
    }
    
    func testRegisterListener() {
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

// MARK: - Listener
extension MKFirestoreMockTest {
    
}

// MARK: - Async Executer
extension MKFirestoreFullMockTest {
    class AsyncGetRecipesHelper {
        var recipes: [Recipe] = []
        let firestore: MKFirestore
        
        init(firestore: MKFirestore) {
            self.firestore = firestore
        }
        
        func executeQuery() {
            Task {
                self.recipes = await firestore.execute(GetAllRecipes()).responseData ?? []
            }
        }
    }
}

// MARK: - Recipe
extension MKFirestoreFullMockTest {
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

// MARK: - Mutation
extension MKFirestoreFullMockTest {
    struct RecipeMutation: MKFirestoreDocumentMutation {
        var firestoreReference: MKFirestoreReference
        var operation: MKFirestoreMutationOperation
        
        init(recipe: Recipe) {
            self.firestoreReference = .collection("Main").document("Test").collection("Recipes")
            self.operation = .setData(from: recipe, merge: false)
        }
    }
}

// MARK: - Get All
extension MKFirestoreFullMockTest {
    struct GetAllRecipes: MKFirestoreCollectionQuery {
        typealias BaseResultData = Recipe
        
        var collectionReference: MKFirestoreCollectionReference = .collection("Main").document("Test").collection("Recipes")
        
        var orderDescriptor: MFirebaseKit.OrderDescriptor? = nil
        var limit: Int? = nil
        var filters: [MFirebaseKit.MKFirestoreQueryFilter] = []
        var mockResultData: [MKFirestoreFullMockTest.Recipe] = []
    }
}

public class MKFirestoreExpectation: XCTestExpectation {
    public enum QueryType: String {
        case deletion, mutation, query
    }
    let firestoreReference: MKFirestoreReference
    let type: QueryType
    
    public init(firestoreReference: MKFirestoreReference, type: QueryType) {
        self.firestoreReference = firestoreReference
        self.type = type
        super.init(description: "\(type) on \(firestoreReference)")
    }
}

extension MKFirestoreExpectation {
    func fulfillIfMatching(path: String, type: QueryType) {
        if self.isMatching(path: path, type: type) {
            self.fulfill()
        }
    }
    func isMatching(path: String, type: QueryType) -> Bool {
        return self.firestoreReference.rawPath == path
        && self.type == type
    }
}

public class MKFirestoreFullMockDebug: MKFirestoreFullMock {
    var expectations: [MKFirestoreExpectation]
    
    public init(
        mockData: [MKFirestoreFullMockData] = [],
        expectations: [MKFirestoreExpectation] = []
    ) {
        self.expectations = expectations
        super.init(mockData: mockData)
    }
    
    public override func executeCollectionQuery<T>(_ query: T) -> MKFirestoreCollectionQueryResponse<T> where T : MKFirestoreCollectionQuery {
        expectations.forEach({ $0.fulfillIfMatching(path: query.firestoreReference.rawPath, type: .query) })
        return super.executeCollectionQuery(query)
    }
    
    public override func executeDocumentQuery<T>(_ query: T) -> MKFirestoreDocumentQueryResponse<T> where T : MKFirestoreDocumentQuery {
        expectations.forEach({ $0.fulfillIfMatching(path: query.firestoreReference.rawPath, type: .query) })
        return super.executeDocumentQuery(query)
    }
    
    public override func executeDeletion(_ deletion: MKFirestoreDocumentDeletion) -> MKFirestoreError? {
        expectations.forEach({ $0.fulfillIfMatching(path: deletion.firestoreReference.rawPath, type: .deletion) })
        return super.executeDeletion(deletion)
    }
    
    @discardableResult
    public override func executeMutation(_ mutation: MKFirestoreDocumentMutation) -> MKFirestoreMutationResponse {
        expectations.forEach({ $0.fulfillIfMatching(path: mutation.firestoreReference.rawPath, type: .mutation) })
        return super.executeMutation(mutation)
    }
}
