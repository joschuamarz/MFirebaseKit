//
//  MKFirestoreDocumentTest.swift
//  
//
//  Created by Joschua Marz on 24.09.23.
//

import XCTest
@testable import MFirebaseKit

final class MKFirestoreDocumentTest: XCTestCase {

    func testPathGeneratingFull() {
        let document = MKFirestoreCollection("ROOT")
            .document("CHILD1")
            .collection("CHILD2")
            .document("CHILD3")
            .collection("CHILD4")
            .document("SELF")
        
        XCTAssertEqual(document.path(), "ROOT/CHILD1/CHILD2/CHILD3/CHILD4/SELF")
    }

    func testPathGeneratingSingle() {
        let document = MKFirestoreCollection("ROOT").document("SELF")
        
        XCTAssertEqual(document.path(), "ROOT/SELF")
    }

}
