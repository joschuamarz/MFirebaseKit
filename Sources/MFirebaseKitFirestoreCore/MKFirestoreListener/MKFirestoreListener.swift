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
    @Published var objectIdMap: [String: Query.BaseResultData] = [:]
    public var objects: [Query.BaseResultData] {
        return objectIdMap.map { $0.value }
    }

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
        objectIdMap.removeAll()
        didFinishInitialLoad = false
    }

    public func replaceQuery(with newQuery: Query) {
        stopListening()
        self.query = newQuery
    }
    
    public func getObject(by id: String) -> Query.BaseResultData? {
        return objectIdMap[id]
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
        var modifiedObjects: [Query.BaseResultData] = []
        for change in changes {
            do {
                let object = try change.object(as: Query.BaseResultData.self)
                switch change.changeType {
                case .added, .modified:
                    modifiedObjects.append(object)
                    objectIdMap.updateValue(object, forKey: "\(object.id)")
                case .removed:
                    objectIdMap.removeValue(forKey: "\(object.id)")
                }
            } catch {
                handle(error)
            }
        }
        
        publishInitialLoading()
        
        // post-processing
        guard let onAddedOrModifiedProcessor else { return }
        let finalModifiedObjects = modifiedObjects
        Task {
            let resultsManager = ResultsManager()
            
            await withTaskGroup(of: (String, Query.BaseResultData?).self) { group in
                for object in finalModifiedObjects {
                    group.addTask {
                        let updatedObject = await onAddedOrModifiedProcessor(object)
                        return ("\(object.id)", updatedObject)
                    }
                }
                
                for await (key, updatedObject) in group {
                    await resultsManager.updateResults(forKey: key, value: updatedObject)
                }
            }
            
            let finalResultsDict = await resultsManager.getResults()
            DispatchQueue.main.async {
                for key in finalResultsDict.keys {
                    if self.objectIdMap.keys.contains(key) {
                        if let object = finalResultsDict[key], let object {
                            self.objectIdMap.updateValue(object, forKey: key)
                        } else {
                            self.objectIdMap.removeValue(forKey: key)
                        }
                    }
                }
            }
        }
    }
    
    actor ResultsManager {
        private var resultsDict: [String: Query.BaseResultData?] = [:]

        func updateResults(forKey key: String, value: Query.BaseResultData?) {
            resultsDict.updateValue(value, forKey: key)
        }

        func getResults() -> [String: Query.BaseResultData?] {
            return resultsDict
        }
    }
}

extension MKFirestoreCollectionListener {
    func handleMockChanges(_ dataMap: [String: [Any]]) {
        let key = query.firestoreReference.leafCollectionPath
        if let objects = dataMap[key] as? [Query.BaseResultData] {
            self.objectIdMap = objects.reduce(into: [String: Query.BaseResultData](), { partialResult, object in
                partialResult.updateValue(object, forKey: "\(object.id)")
            })
        }
    }
}
