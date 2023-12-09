//
//  MKFirestoreCollectionListenerTest.swift
//  
//
//  Created by Joschua Marz on 07.12.23.
//

import XCTest
@testable import MFirebaseKit

final class MKFirestoreCollectionListenerTest: XCTestCase {
    
    struct TestResultData: Codable, Identifiable, Equatable {
        let id: String
        var name: String
    }
    
    struct TestCollectionQuery: MKFirestoreCollectionQuery {
        typealias BaseResultData = TestResultData
        
        var collectionReference: MFirebaseKit.MKFirestoreCollectionReference = .collection("Test")
        
        var orderDescriptor: MFirebaseKit.OrderDescriptor? = nil
        var limit: Int? = nil
        var filters: [MFirebaseKit.MKFirestoreQueryFilter] = []

        var mockResultData: [MKFirestoreCollectionListenerTest.TestResultData] = [
            .init(id: "1", name: "Test 1"),
            .init(id: "2", name: "Test 2")
        ]
    }
    
    let query: TestCollectionQuery = TestCollectionQuery()
    
    // MARK: - Setup
    
    func testListener_Setup() {
        let listener = MKFirestoreCollectionListener(
            query: query, 
            firestore: MKFirestoreMock()
        )
        XCTAssertFalse(listener.isListening)
        // start listening
        listener.startListening()
        XCTAssertTrue(listener.isListening)
        // handle new item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        XCTAssertEqual(listener.objects.count, 1)
        // stop listening - removes all items
        listener.stopListening()
        XCTAssertFalse(listener.isListening)
        XCTAssertEqual(listener.objects.count, 0)
        // does not handle events when disabled
        listener.onAdded(newItem)
        XCTAssertEqual(listener.objects.count, 0)
    }
    
    // MARK: - Add

    func testListener_OnAdded() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock()
        )
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Expect item to be added
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertEqual(listener.objects.last, newItem)
    }
    
    func testListener_OnAdded_AdditionalHandler() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock(),
            onAddedAdditionalHandler:  { object in
                var newObject = object
                newObject.name = "Test Modified"
                return newObject
            })
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Item should be added with modified name
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertNotEqual(listener.objects.last, newItem)
        XCTAssertEqual(listener.objects.last?.name, "Test Modified")
    }
    
    func testListener_OnAdded_AdditionalHandler_excludesItems() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock(),
            onAddedAdditionalHandler:  { object in
                if object.id == "11" {
                    return nil
                }
                
                return object
            })
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Item should be added
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertEqual(listener.objects.last, newItem)
        // Item should be catched by filter
        let newItem2 = TestResultData(id: "11", name: "Test 11")
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertEqual(listener.objects.last, newItem)
    }
    
    // MARK: - Modify

    func testListener_OnModified_itemExists() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock()
        )
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Modify item with same id
        let modifiedItem = TestResultData(id: "10", name: "Test 10 Modified")
        listener.onModified(modifiedItem)
        // Item should be updated
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertEqual(listener.objects.last, modifiedItem)
    }
    
    func testListener_OnModified_itemNotExists() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock()
        )
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Modify item with different id
        let modifiedItem = TestResultData(id: "11", name: "Test 10 Modified")
        listener.onModified(modifiedItem)
        // Item should be added
        XCTAssertEqual(listener.objects.count, 2)
        XCTAssertEqual(listener.objects.last, modifiedItem)
    }
    
    func testListener_OnModified_AdditionalHandler() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock(),
            onModifiedAdditionalHandler:  { object in
                var newObject = object
                newObject.name = "Test 10 Modified Again"
                return newObject
            })
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        let modifiedItem = TestResultData(id: "10", name: "Test 10 Modified")
        listener.onModified(modifiedItem)
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertNotEqual(listener.objects.last, newItem)
        XCTAssertEqual(listener.objects.last?.name, "Test 10 Modified Again")
    }
    
    // MARK: - Remove
    
    func testListener_OnRemoved_itemExists() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock()
        )
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Remove same item
        listener.onRemoved(newItem)
        // Item should be updated
        XCTAssertEqual(listener.objects.count, 0)
    }
    
    func testListener_OnRemoved_itemNotExists() {
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock()
        )
        listener.startListening()
        // Add first item
        let newItem = TestResultData(id: "10", name: "Test 10")
        listener.onAdded(newItem)
        // Remove item with different id
        let removedItem = TestResultData(id: "11", name: "Test 11")
        listener.onRemoved(removedItem)
        // Nothing should change
        XCTAssertEqual(listener.objects.count, 1)
        XCTAssertEqual(listener.objects.last, newItem)
    }
    
    // MARK: - Mocked Changes
    
    func testMockedChanges() {
        var addActionCounter = 0
        var removeActionCounter = 0
        let firstAdd = XCTestExpectation(description: "First item added")
        let secondAdd = XCTestExpectation(description: "Second item added")
        let firstRemoval = XCTestExpectation(description: "First item removed")
        let secondRemoval = XCTestExpectation(description: "First item removed")
        let firstReAdd = XCTestExpectation(description: "First item re-added")
        let secondReAdd = XCTestExpectation(description: "Second item re-added")
        
        let listener = MKFirestoreCollectionListener(
            query: query,
            firestore: MKFirestoreMock(listenerMockMode: .auto),
            onAddedAdditionalHandler: { object in
                switch addActionCounter {
                case 0:
                    firstAdd.fulfill()
                case 1:
                    secondAdd.fulfill()
                case 2:
                    firstReAdd.fulfill()
                case 3:
                    secondReAdd.fulfill()
                default:
                    XCTFail("More add actions than expected")
                }
                addActionCounter += 1
                return object
            },
            onRemovedAdditionalHandler: { object in
                switch removeActionCounter {
                case 0:
                    firstRemoval.fulfill()
                case 1:
                    secondRemoval.fulfill()
                default:
                    XCTFail("More remove actions than expected")
                }
                removeActionCounter += 1
                return object
            }
        )
        listener.startListening()
        
        wait(for: [
            firstAdd,
            secondAdd
        ], timeout: 5)
        
        XCTAssertEqual(listener.objects.count, 2)
        
        wait(for: [
            firstRemoval,
            secondRemoval
        ], timeout: 5)
        
        XCTAssertEqual(listener.objects.count, 0)

        wait(for: [
            firstReAdd,
            secondReAdd
        ], timeout: 5)
        
        XCTAssertEqual(listener.objects.count, 2)
        listener.stopListening()
    }
}
