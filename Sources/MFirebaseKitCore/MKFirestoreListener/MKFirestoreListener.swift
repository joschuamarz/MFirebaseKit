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
    var type: MKDocumentChangeType { get }
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
    public typealias AdditionalChangeHandler = (Query.BaseResultData) async ->Query.BaseResultData?
    public typealias ErrorHandler = (Error)->Void
    public typealias AddedOrModifiedProcessor = (Query.BaseResultData) async -> Query.BaseResultData?

    // Listener Registration
    public let id: String = UUID().uuidString
    private var listenerRegistration: MKListenerRegistration?
    public var isListening: Bool {
        return listenerRegistration != nil
    }

    @Published public var didFinishInitialLoad: Bool = false
    @Published public var objects: [Query.BaseResultData] = []
    
    public var query: Query
    private let firestore: MKFirestore
    
    // Handler
    public var onDidFinishInitialLoading: (()->Void)?
    public var onErrorHandler: ErrorHandler?
    
    private var isMockedListener: Bool {
        return firestore is MKFirestoreMock
    }
    
    /// Processes any object that will get added or modified
    ///
    /// Not called on objects that will be removed
    /// You can use this for example to load a subcollection and add it to the object's properties
    public var onAddedOrModifiedProcessor: AddedOrModifiedProcessor?
    
    // MARK: - Init
    public init(
        query: Query,
        firestore: MKFirestore,
        onDidFinishInitialLoading: (()->Void)? = nil,
        onAddedOrModifiedProcessor: AddedOrModifiedProcessor? = nil,
        onErrorHandler: ErrorHandler? = nil
    ) {
        self.query = query
        self.firestore = firestore
        self.onDidFinishInitialLoading = onDidFinishInitialLoading
        self.onAddedOrModifiedProcessor = onAddedOrModifiedProcessor
        self.onErrorHandler = onErrorHandler
    }
    
    // MARK: - State
    public func startListening() {
        guard !isListening else { return }
        listenerRegistration = firestore.addCollectionListener(self)
    }
    
    public func stopListening() {
        listenerRegistration?.remove()
        objects.removeAll()
        listenerRegistration = nil
        didFinishInitialLoad = false
    }
    
    public func replaceQuery(with query: Query) {
        stopListening()
        self.query = query
    }
    
    // MARK: - Error Handling
    public func handle(_ error: Error) {
        // handle error
        onErrorHandler?(error)
    }
    
    // MARK: - Object change handling
    private func publishInitialLoading() {
        if !didFinishInitialLoad {
            didFinishInitialLoad = true
            onDidFinishInitialLoading?()
        }
    }
    
    actor ResultActor {
        var results: [Query.BaseResultData]
        
        init(results: [Query.BaseResultData]) {
            self.results = results
        }
        
        func add(_ result: Query.BaseResultData) {
            results.append(result)
        }
        
        func replace(with result: Query.BaseResultData) -> Bool {
            if let index = results.firstIndex(where: { $0.id == result.id }) {
                results[index] = result
                return true
            }
            return false
        }
        
        func removeAll(by id: Query.BaseResultData.ID) {
            results.removeAll(where: { $0.id == id })
        }
    }
    // MARK: - Universal change handler
    func handle(_ changes: [MKDocumentChange]?, error: Error?, for query: Query) {
        guard isListening && query.isEqual(to: self.query) else { return }
        guard let changes else {
            if let error { handle(error) }
            return
        }
        Task {
            let dispatchGroup = DispatchGroup()
            let resultsActor = ResultActor(results: self.objects)
            for change in changes {
                dispatchGroup.enter()
                Task(priority: .background) {
                    do {
                        let object = try change.object(as: Query.BaseResultData.self)
                        switch change.type {
                        case .added:
                            if let newObject = await processObjectIfNeeded(object) {
                                await resultsActor.add(newObject)
                            }
                        case .modified:
                            if let newObject = await processObjectIfNeeded(object) {
                                if await !resultsActor.replace(with: newObject) {
                                    await resultsActor.add(newObject)
                                }
                            }
                        case .removed:
                            await resultsActor.removeAll(by: object.id)
                        }
                    } catch {
                        handle(error)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .global()) {
                Task {
                    let finalResults = await resultsActor.results
                    print("$ MKFirestoreListener: processed \(changes.count) changes")
                    DispatchQueue.main.async {
                        self.objects = finalResults
                        self.publishInitialLoading()
                    }
                }
            }
        }
    }
    
    private func processObjectIfNeeded(_ object: Query.BaseResultData) async -> Query.BaseResultData? {
        guard let onAddedOrModifiedProcessor else { return object }
        return await onAddedOrModifiedProcessor(object)
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
