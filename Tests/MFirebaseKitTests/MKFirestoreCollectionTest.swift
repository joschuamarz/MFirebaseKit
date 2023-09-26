//
//  MKFirestoreCollectionTest.swift
//  
//
//  Created by Joschua Marz on 24.09.23.
//

import XCTest
@testable import MFirebaseKit

final class MKFirestoreCollectionTest: XCTestCase {

    func testPathGeneratingFull() {
        let collection = MKFirestoreCollection("ROOT")
            .document("CHILD1")
            .collection("CHILD2")
            .document("CHILD3")
            .collection("SELF")
        
        XCTAssertEqual(collection.path(), "ROOT/CHILD1/CHILD2/CHILD3/SELF")
    }

    func testPathGeneratingSingle() {
        let collection = MKFirestoreCollection("ROOT")
        
        XCTAssertEqual(collection.path(), "ROOT")
    }
}
