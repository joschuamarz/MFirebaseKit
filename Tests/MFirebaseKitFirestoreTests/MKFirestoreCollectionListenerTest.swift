//
//  MKFirestoreCollectionListenerTest.swift
//  
//
//  Created by Joschua Marz on 07.12.23.
//

import XCTest
import MFirebaseKitFirestoreCore
import MFirebaseKitFirestoreDebug

final class MKFirestoreCollectionListenerTest: XCTestCase {
    
    let collectionReference = MKFirestoreCollectionReference.collection("SomeCollection")

    func testListenerReceivesUpdates() async {
        let firestore = MKFirestoreMockDebug()

        // Define initial mock data
        let initialData: [String: MockResultData] = [
            "1": MockResultData(name: "Item 1"),
            "2": MockResultData(name: "Item 2")
        ]

        // Set up the expectation for the listener registration
        let listenerExpectation = MKFirestoreExpectation(
            firestoreReference: collectionReference,
            type: .listener
        )

        // Register initial data for this collection
        firestore.register(
            initialData: initialData,
            for: collectionReference
        )

        firestore.expectations = [listenerExpectation]

        // Track change notification
        let dataChangedExpectation = XCTestExpectation(description: "Data updated via listener")

        // Create listener
        let query = MockCollectionQuery(collectionReference: collectionReference)
        let listener = MKFirestoreCollectionListener(query: query, firestore: firestore)

        listener.onAdded = { _ in
            dataChangedExpectation.fulfill()
        }

        // Start listening
        listener.startListening()

        // Wait for the mock listener to trigger the callback
        await fulfillment(of: [listenerExpectation, dataChangedExpectation], timeout: 5)

        // Validate received data
        let receivedData = listener.objects.sorted { $0.id < $1.id }
        let expectedData = initialData.map { $0.value }.sorted { $0.id < $1.id }
        XCTAssertEqual(receivedData, expectedData)
    }
    
    func testMultipleStartListeningDoesNotDuplicateCallbacks() async {
        let firestore = MKFirestoreMockDebug()
        
        let initialData: [String: MockResultData] = [
            "1": MockResultData(name: "Item 1")
        ]
        
        let listenerExpectation = MKFirestoreExpectation(
            firestoreReference: collectionReference,
            type: .listener
        )
        
        firestore.register(initialData: initialData, for: collectionReference)
        firestore.expectations = [listenerExpectation]

        let query = MockCollectionQuery(collectionReference: collectionReference)
        let listener = MKFirestoreCollectionListener(query: query, firestore: firestore)

        var receivedCount = 0
        let dataChangedExpectation = XCTestExpectation(description: "Data updated via listener")
        dataChangedExpectation.expectedFulfillmentCount = 1

        listener.onAdded = { _ in
            receivedCount += 1
            dataChangedExpectation.fulfill()
        }

        listener.startListening()
        listener.startListening() // should not double-register

        await fulfillment(of: [listenerExpectation, dataChangedExpectation], timeout: 5)
        XCTAssertEqual(receivedCount, 1)
    }
    
    /// Tests that updates to existing documents trigger `onModified` and overwrite existing data.
    func testListenerReceivesModifications() async {
        let firestore = MKFirestoreMockDebug()
        
        let original = MockResultData(name: "Original")
        let updated = MockResultData(id: original.id, name: "Updated")
        
        let initialData: [String: MockResultData] = [original.id: original]
        
        // Register original data and expect a listener
        firestore.register(initialData: initialData, for: collectionReference)
        firestore.expectations = [
            MKFirestoreExpectation(firestoreReference: collectionReference, type: .listener)
        ]
        
        let modificationExpectation = XCTestExpectation(description: "Item modified via listener")
        
        let query = MockCollectionQuery(collectionReference: collectionReference)
        let listener = MKFirestoreCollectionListener(query: query, firestore: firestore)
        
        // Listener should detect the modification
        listener.onModified = { item in
            if item.name == "Updated" {
                modificationExpectation.fulfill()
            }
        }
        
        listener.startListening()
        
        // Simulate the document modification
        firestore.simulateChange(
            for: collectionReference,
            changeType: .modified(documentID: original.id, data: updated)
        )
        
        // Wait for listener to be ready and receive modification
        await fulfillment(of: firestore.expectations + [modificationExpectation], timeout: 5)
        
        // Check if listener updated the stored object correctly
        XCTAssertEqual(listener.objects, [updated])
    }
    
    /// Tests that the listener correctly handles multiple concurrent updates to the same collection.
    func testConcurrentListenerUsage() async {
        let firestore = MKFirestoreMockDebug()
        
        // 5 separate batches of mock data for different updates
        let mockBatches: [[String: MockResultData]] = (0..<5).map { batch in
            [
                UUID().uuidString: MockResultData(name: "Batch \(batch) - A"),
                UUID().uuidString: MockResultData(name: "Batch \(batch) - B")
            ]
        }
        
        // Expectation: listener is set up once
        let listenerExpectation = MKFirestoreExpectation(
            firestoreReference: collectionReference,
            type: .listener
        )
        firestore.expectations = [listenerExpectation]
        
        let query = MockCollectionQuery(collectionReference: collectionReference)
        let listener = MKFirestoreCollectionListener(query: query, firestore: firestore)
        
        // Expectation: all batches will trigger `onAdded` calls
        let totalExpectedAdds = mockBatches.reduce(0) { $0 + $1.count }
        let dataChangedExpectation = XCTestExpectation(description: "All data added via listener")
        dataChangedExpectation.expectedFulfillmentCount = totalExpectedAdds
        
        // Fulfill on each added document
        listener.onAdded = { _ in
            dataChangedExpectation.fulfill()
        }
        
        listener.startListening()
        
        // Concurrently simulate changes from different async tasks
        await withTaskGroup(of: Void.self) { group in
            for batch in mockBatches {
                group.addTask {
                    for (id, item) in batch {
                        firestore.simulateChange(
                            for: self.collectionReference,
                            changeType: .added(documentID: id, data: item)
                        )
                    }
                }
            }
        }
        
        // Wait for all simulated adds to complete
        await fulfillment(of: [listenerExpectation, dataChangedExpectation], timeout: 5)
        
        // Ensure all added items are now in the listener’s data
        let expected = mockBatches.flatMap { $0.values }.sorted(by: { $0.id < $1.id })
        let actual = listener.objects.sorted(by: { $0.id < $1.id })
        XCTAssertEqual(expected, actual)
    }
    
    /// Tests that the listener receives `onRemoved` events correctly.
    func testListenerReceivesRemovals() async {
        let firestore = MKFirestoreMockDebug()
        
        // Initial data with two documents
        let initialData: [String: MockResultData] = [
            "1": MockResultData(name: "Item 1"),
            "2": MockResultData(name: "Item 2")
        ]
        
        // Expectation for listener setup
        let listenerExpectation = MKFirestoreExpectation(
            firestoreReference: collectionReference,
            type: .listener
        )
        
        // Register the initial data to the mock Firestore
        firestore.register(initialData: initialData, for: collectionReference)
        firestore.expectations = [listenerExpectation]
        
        // Expect that one document will be removed
        let removedExpectation = XCTestExpectation(description: "Item removed via listener")
        
        let query = MockCollectionQuery(collectionReference: collectionReference)
        let listener = MKFirestoreCollectionListener(query: query, firestore: firestore)
        
        listener.onRemoved = { _ in
            removedExpectation.fulfill()
        }
        
        // Start listening for changes
        listener.startListening()
        
        // Simulate document removal
        firestore.simulateChange(
            for: collectionReference,
            changeType: .removed(documentID: "1")
        )
        
        // Wait for both registration and removal callback
        await fulfillment(of: [listenerExpectation, removedExpectation], timeout: 5)
        
        // Ensure only the remaining item is present
        let receivedData = listener.objects
        XCTAssertEqual(receivedData, [initialData["2"]!])
    }
}

struct MockCollectionQuery: MKFirestoreCollectionQuery {
    
    init(collectionReference: MFirebaseKitFirestoreCore.MKFirestoreCollectionReference) {
        self.collectionReference = collectionReference
    }
    
    var collectionReference: MFirebaseKitFirestoreCore.MKFirestoreCollectionReference
    
    var mockResultData: [MockResultData] = []
    var orderDescriptor: MFirebaseKitFirestoreCore.OrderDescriptor? = nil
    var limit: Int? = nil
    var filters: [MFirebaseKitFirestoreCore.MKFirestoreQueryFilter] = []
}
