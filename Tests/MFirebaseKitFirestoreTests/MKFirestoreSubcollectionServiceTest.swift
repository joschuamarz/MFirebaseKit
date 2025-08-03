//
//  MKFirestoreSubcollectionService.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 02.08.25.
//

import XCTest
@testable import MFirebaseKitFirestoreCore
@testable import MFirebaseKitFirestoreDebug

final class MKFirestoreSubcollectionServiceTest: XCTestCase {
    
    let baseCollectionReference = MKFirestoreCollectionReference.collection("BaseCollection")
    let subCollectionName = "SubCollection"
    
    func testConcurrentCalls() async {
        
        let documentIds: [String] = [
            "BaseDocument1",
            "BaseDocument2",
            "BaseDocument3",
            "BaseDocument4",
            "BaseDocument5",
        ]
        
        let expectedSubcollectionMocks: [String: [MockResultData]] = [
            "BaseDocument1": [MockResultData(name: "1-A"), MockResultData(name: "1-B")],
            "BaseDocument2": [MockResultData(name: "2-A"), MockResultData(name: "2-B")],
            "BaseDocument3": [MockResultData(name: "3-A"), MockResultData(name: "3-B")],
            "BaseDocument4": [MockResultData(name: "4-A"), MockResultData(name: "4-B")],
            "BaseDocument5": [MockResultData(name: "5-A"), MockResultData(name: "5-B")],
        ]
        
        let expectation = XCTestExpectation(description: "Subcollection service changed")
        expectation.expectedFulfillmentCount = 5
        
        let firestore = MKFirestoreMockDebug()
        var expectations: [MKFirestoreExpectation] = []
        for documentId in documentIds {
            firestore.register(
                autoResponse: .success(data: expectedSubcollectionMocks[documentId]!),
                for: baseCollectionReference.document(documentId).collection(subCollectionName)
            )
            expectations.append(MKFirestoreExpectation(firestoreReference: baseCollectionReference.document(documentId).collection(subCollectionName), type: .query))
        }
        
        firestore.expectations = expectations
        
        let subCollectionService = MKFirestoreSubcollectionService<MockResultData>(
            firestore: firestore,
            baseCollectionReference: baseCollectionReference,
            subcollectionName: subCollectionName
        )
        
        await withTaskGroup(of: Void.self) { group in
            for documentId in documentIds {
                group.addTask {
                    subCollectionService.loadSubcollection(for: documentId)
                }
            }
        }
        
        
        await fulfillment(of: expectations, timeout: 5)
        
        for documentId in documentIds {
            XCTAssertEqual(subCollectionService.getSubcollection(for: documentId), expectedSubcollectionMocks[documentId]!)
        }
    }
}

struct MockResultData: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    
    init(id: String? = nil, name: String) {
        self.id = id ?? UUID().uuidString
        self.name = name
    }
}

