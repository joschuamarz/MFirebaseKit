//
//  File.swift
//  
//
//  Created by Joschua Marz on 26.09.23.
//

import Foundation

public protocol MKFirestore {
    func executeQuery<T: MKFirestoreQuery>(_ query: T) async -> MKFirestoreQueryResponse<T>
    func executeQuery<T: MKFirestoreQuery>(_ query: T, completion: @escaping (MKFirestoreQueryResponse<T>)->Void)
}
