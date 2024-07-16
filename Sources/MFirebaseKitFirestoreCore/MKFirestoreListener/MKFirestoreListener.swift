//
//  File.swift
//  
//
//  Created by Joschua Marz on 06.12.23.
//

import Foundation
import Combine

public typealias VoidHandler = () -> Void

public enum MKDocumentChangeType {
    case added, modified, removed
}
public protocol MKDocumentChange {
    var changeType: MKDocumentChangeType { get }
    func object<T: Decodable>(as type: T.Type) throws -> T
}

public class MockListenerRegistration: NSObject, MKListenerRegistration {
    public let onChange: VoidHandler
    public let onRemove: VoidHandler
    
    public init(
        onChange: @escaping VoidHandler = { },
        onRemove: @escaping VoidHandler = { }
    ) {
        self.onChange = onChange
        self.onRemove = onRemove
    }
    
    public func remove() {
        onRemove()
    }
}

public class MKFirestoreCollectionListener<Query: MKFirestoreCollectionQuery>: ObservableObject, Identifiable {
    public typealias AdditionalChangeHandler = (Query.BaseResultData) async -> Query.BaseResultData?
    public typealias ErrorHandler = (Error) -> Void
    public typealias AddedOrModifiedProcessor = (Query.BaseResultData) async -> Query.BaseResultData?

    // Listener Registration
    public let id: String = UUID().uuidString
    private var listenerRegistration: MKListenerRegistration?
    public var isListening: Bool { listenerRegistration != nil }

    @Published public var didFinishInitialLoad: Bool = false
    @Published public var objects: [Query.BaseResultData] = []
    @Published private var objectIdMap: [String: Query.BaseResultData] = [:]

    public var query: Query
    private let firestore: MKFirestore

    // Handlers
    public var onDidFinishInitialLoading: (() -> Void)?
    public var onErrorHandler: ErrorHandler?
    public var onAddedOrModifiedProcessor: AddedOrModifiedProcessor?

    private var isMockedListener: Bool {
        return firestore is MKFirestoreMock
    }

    // MARK: - Init
    public init(
        query: Query,
        firestore: MKFirestore,
        onDidFinishInitialLoading: (() -> Void)? = nil,
        onAddedOrModifiedProcessor: AddedOrModifiedProcessor? = nil,
        onErrorHandler: ErrorHandler? = nil
    ) {
        self.query = query
        self.firestore = firestore
        self.onDidFinishInitialLoading = onDidFinishInitialLoading
        self.onAddedOrModifiedProcessor = onAddedOrModifiedProcessor
        self.onErrorHandler = onErrorHandler
    }

    // MARK: - State Management
    public func startListening() {
        guard !isListening else { return }
        listenerRegistration = firestore.addCollectionListener(self)
    }

    public func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        objects.removeAll()
        didFinishInitialLoad = false
    }

    public func replaceQuery(with newQuery: Query) {
        stopListening()
        self.query = newQuery
    }
    
    public func getObject(by id: String) -> Query.BaseResultData? {
        if let object = objectIdMap[id] {
            return object
        } else if let object = objects.first(where: { "\($0.id)" == id }) {
            return object
        }
        return nil
    }

    // MARK: - Error Handling
    public func handle(_ error: Error) {
        onErrorHandler?(error)
    }

    // MARK: - Object Change Handling
    private func publishInitialLoading() {
        guard !didFinishInitialLoad else { return }
        didFinishInitialLoad = true
        onDidFinishInitialLoading?()
    }

    // MARK: - Universal Change Handler
    public func handle(_ changes: [MKDocumentChange]?, error: Error?, for query: Query) {
        guard isListening && query.isEqual(to: self.query) else { return }
        
        if let error = error {
            handle(error)
            return
        }
        
        guard let changes = changes else { return }
        for change in changes {
            do {
                let object = try change.object(as: Query.BaseResultData.self)
                switch change.changeType {
                case .added:
                    objects.append(object)
                    objectIdMap.updateValue(object, forKey: "\(object.id)")
                case .modified:
                    if let index = objects.firstIndex(where: { $0.id == object.id }) {
                        objects[index] = object
                    }
                    objectIdMap.updateValue(object, forKey: "\(object.id)")
                case .removed:
                    objects.removeAll { $0.id == object.id }
                    objectIdMap.removeValue(forKey: "\(object.id)")
                }
            } catch {
                handle(error)
            }
        }
        
        publishInitialLoading()
    }
}

extension MKFirestoreCollectionListener {
    func handleMockChanges(_ dataMap: [String: [Any]]) {
        let key = query.firestoreReference.leafCollectionPath
        if let objects = dataMap[key] as? [Query.BaseResultData] {
            self.objects = objects
        }
    }
}
