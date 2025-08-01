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

protocol FirestoreExecutor {
    func run(_ operation: @escaping @Sendable () async -> Void)
}

public class MKFirestoreCollectionListener<Query: MKFirestoreCollectionQuery>: ObservableObject, Identifiable {
    public typealias AdditionalChangeHandler = (Query.BaseResultData) async -> Query.BaseResultData?
    public typealias ErrorHandler = (Error) -> Void
    public typealias AddedOrModifiedProcessor = (Query.BaseResultData) async -> Query.BaseResultData?

    public let id: String = UUID().uuidString
    
    private var listenerRegistration: MKListenerRegistration?
    public var isListening: Bool { listenerRegistration != nil }
    
    private let firestore: MKFirestore

    @Published public var didFinishInitialLoad: Bool = false
    
    @Published var objectIdMap: [String: Query.BaseResultData] = [:]
   
    public var objects: [Query.BaseResultData] {
        return objectIdMap.map { $0.value }
    }

    public var query: Query

    // Handlers
    public var onDidFinishInitialLoading: (() -> Void)?
    public var onErrorHandler: ErrorHandler?
    public var onAddedOrModifiedProcessor: AddedOrModifiedProcessor?
    
    private let updateHandler: any MKFirestoreCollectionListenerUpdateHandlerProtocol

    private var isMockedListener: Bool {
        return firestore is MKFirestoreMock
        || firestore is MKFirestoreListenerMock<Query.BaseResultData>
        || firestore is MKFirestoreFullMock
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
        if isMockedListener {
            self.updateHandler = MKFirestoreCollectionListenerUpdateHandlerMock<Query>()
        } else {
            self.updateHandler = MKFirestoreCollectionListenerUpdateHandler<Query>()
        }
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
        
        if let error  {
            handle(error)
            return
        }

        guard let changes else { return }

        updateHandler.handleChanges(
            changes: changes,
            initialObjectIdMap: objectIdMap,
            onAddedOrModifiedProcessor: onAddedOrModifiedProcessor,
            onError: handle(_:),
            onWriteHandler: { objectIdMap = $0 }
        )
        
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

// MARK: - Update handling
extension MKFirestoreCollectionListener {
    
}

open class MKFirestoreCollectionListenerUpdateHandlerProtocol {
    associatedtype Query: MKFirestoreCollectionQuery
    typealias WriteHandler = ([String: Query.BaseResultData])->Void
    
    func handleChanges(
        changes: [MKDocumentChange],
        initialObjectIdMap: [String: Query.BaseResultData],
        onAddedOrModifiedProcessor: ((Query.BaseResultData) async -> Query.BaseResultData?)?,
        onError: ((Error)->Void)?,
        onWriteHandler: @escaping WriteHandler
    )
    
}

public struct MKFirestoreCollectionListenerUpdateHandlerMock<Query: MKFirestoreCollectionQuery>: MKFirestoreCollectionListenerUpdateHandlerProtocol {
    func handleChanges(
        changes: [any MKDocumentChange],
        initialObjectIdMap: [String : Query.BaseResultData],
        onAddedOrModifiedProcessor: ((Query.BaseResultData) async -> Query.BaseResultData?)?,
        onError: ((any Error) -> Void)?,
        onWriteHandler: @escaping WriteHandler
    ) {
        var updatedObjectIdMap = initialObjectIdMap
        // Run updates synchronously
        for change in changes {
            do {
                let object = try change.object(as: Query.BaseResultData.self)
                let key = "\(object.id)"
                switch change.changeType {
                case .added, .modified:
                    updatedObjectIdMap[key] = object
                case .removed:
                    updatedObjectIdMap.removeValue(forKey: key)
                }
            } catch {
                onError?(error)
            }
        }
    }
}

public struct MKFirestoreCollectionListenerUpdateHandler<Query: MKFirestoreCollectionQuery>: MKFirestoreCollectionListenerUpdateHandlerProtocol {
    
    let handlerQueue = UpdateHandlerQueue()
    
    func handleChanges(
        changes: [any MKDocumentChange],
        initialObjectIdMap: [String : Query.BaseResultData],
        onAddedOrModifiedProcessor: ((Query.BaseResultData) async -> Query.BaseResultData?)?,
        onError: ((any Error) -> Void)?,
        onWriteHandler: @escaping ([String : Query.BaseResultData]) -> Void
    ) {
        Task {
            // Run updates asynchronously
            let updatedMap = await handlerQueue.handleChanges(
                changes: changes,
                objectIdMap: initialObjectIdMap,
                onAddedOrModifiedProcessor: onAddedOrModifiedProcessor,
                onError: onError
            )

            // Write updates on the main thread
            await MainActor.run { onWriteHandler(updatedMap) }
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
    
    actor UpdateHandlerQueue {
        func handleChanges(
            changes: [MKDocumentChange],
            objectIdMap: [String: Query.BaseResultData],
            onAddedOrModifiedProcessor: ((Query.BaseResultData) async -> Query.BaseResultData?)?,
            onError: ((Error)->Void)?
        ) async -> [String: Query.BaseResultData] {
            // Store all objects that are either added or modified
            var modifiedObjects: [Query.BaseResultData] = []
            // Local copy to change the objectIdMap
            var updatedObjectIdMap = objectIdMap

            // MARK: Step 1: Apply changes (add/modify/remove)
            
            for change in changes {
                do {
                    // Try to decode document into expected object
                    let object = try change.object(as: Query.BaseResultData.self)
                    let key = "\(object.id)"
                    switch change.changeType {
                    case .added, .modified:
                        modifiedObjects.append(object)
                        updatedObjectIdMap[key] = object
                    case .removed:
                        updatedObjectIdMap.removeValue(forKey: key)
                    }
                } catch {
                    onError?(error)
                }
            }

            // Return if there is no post-processing required
            guard let onAddedOrModifiedProcessor else { return updatedObjectIdMap }

            // MARK: Step 2: Run post-processing in parallel
            
            // Manager to serialize parallel writes to a shared results dictionary
            let resultsManager = ResultsManager()
            
            await withTaskGroup(of: (String, Query.BaseResultData?).self) { group in
                // For each modified object, run the processor which can modify / delete a result
                for object in modifiedObjects {
                    group.addTask {
                        let updatedObject = await onAddedOrModifiedProcessor(object)
                        return ("\(object.id)", updatedObject)
                    }
                }
                // Each task group item can now update the corresponding item in the results map
                for await (key, updatedObject) in group {
                    await resultsManager.updateResults(forKey: key, value: updatedObject)
                }
            }
            
            // Wait for all parallel writes to happen
            let finalResultsDict = await resultsManager.getResults()

            // MARK: Step 3: Merge processed results
            
            for (key, object) in finalResultsDict {
                if let object {
                    updatedObjectIdMap[key] = object
                } else {
                    updatedObjectIdMap.removeValue(forKey: key)
                }
            }
            return updatedObjectIdMap
        }
    }
    
}
