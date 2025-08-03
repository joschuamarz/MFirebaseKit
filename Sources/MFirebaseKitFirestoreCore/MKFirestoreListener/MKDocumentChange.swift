//
//  File.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 03.08.25.
//

import Foundation

public enum MKDocumentChangeType {
    case added, modified, removed
}
public protocol MKDocumentChange {
    var changeType: MKDocumentChangeType { get }
    var documentID: String { get }
    func object<T: Decodable>(as type: T.Type) throws -> T
}
