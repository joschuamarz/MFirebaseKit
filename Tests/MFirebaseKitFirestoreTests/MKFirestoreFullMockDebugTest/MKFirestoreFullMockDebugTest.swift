//
//  MKFirestoreFullMockDebugTest.swift
//  
//
//  Created by Joschua Marz on 03.05.24.
//

import XCTest
import MFirebaseKitFirestoreCore
@testable import MFirebaseKitFirestoreDebug

final class MKFirestoreFullMockDebugTest: XCTestCase {

    func testListenerInitialLoad() async {
        let initialLoadExpectation = MKFirestoreExpectation(
            firestoreReference: BaseQuery().firestoreReference,
            type: .listener
        )
        let fullMock = MKFirestoreFullMockDebug(
            mockData: [
                .init(
                    firestoreReference: BaseQuery().firestoreReference,
                    data: [Recipe(id: "some", name: "mock")]
                ),
            ],
            expectations: [initialLoadExpectation]
        )
        
        let listener = MKFirestoreCollectionListener(
            query: BaseQuery(),
            firestore: fullMock
        )
        listener.startListening()
        await fulfillment(of: [initialLoadExpectation])
        XCTAssertTrue(listener.didFinishInitialLoad)
    }

}

extension MKFirestoreFullMockDebugTest {
    struct Recipe: Codable, Identifiable {
        let id: String
        let name: String
    }
    struct BaseQuery: MKFirestoreCollectionQuery {
        typealias BaseResultData = Recipe
        var collectionReference: MKFirestoreCollectionReference = .collection("Test")
        var orderDescriptor: OrderDescriptor? = nil
        var limit: Int? = nil
        var filters: [MKFirestoreQueryFilter] = []
        var mockResultData: [Recipe] = []
    }
}
