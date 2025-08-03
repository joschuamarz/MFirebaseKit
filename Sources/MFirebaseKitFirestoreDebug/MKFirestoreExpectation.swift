//
//  File.swift
//  
//
//  Created by Joschua Marz on 03.05.24.
//

import Foundation
import XCTest
import MFirebaseKitFirestoreCore

public class MKFirestoreExpectation: XCTestExpectation, @unchecked Sendable {
    public enum QueryType: String {
        case deletion, mutation, query, listener
    }
    let firestoreReference: MKFirestoreReference
    let type: QueryType
    
    public init(firestoreReference: MKFirestoreReference, type: QueryType) {
        self.firestoreReference = firestoreReference
        self.type = type
        super.init(description: "\(type) on \(firestoreReference.rawPath as String)")
    }
}

extension MKFirestoreExpectation {
    func isMatching(path: String, type: QueryType) -> Bool {
        return self.firestoreReference.rawPath == path
        && self.type == type
    }
}

extension Array {
    mutating func removeFirst(where shouldBeRemoved: (Element) throws -> Bool) rethrows -> Element? {
        if let index = try firstIndex(where: shouldBeRemoved) {
            return remove(at: index)
        }
        return nil
    }
}
