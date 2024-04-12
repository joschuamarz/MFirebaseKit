//
//  File.swift
//  
//
//  Created by Joschua Marz on 06.12.23.
//

import FirebaseFirestore

public class MockListenerRegistration: NSObject, ListenerRegistration {
    let onRemove: ()->Void
    
    init(onRemove: @escaping () -> Void) {
        self.onRemove = onRemove
    }
    
    public func remove() {
        onRemove()
    }
}

public protocol MKFirestoreListener {
    associatedtype Query: MKFirestoreQuery
    typealias ChangeHandler = ([DocumentChange])->Void
    
    var query: Query { get }
    func handle(_ change: DocumentChange?, error: Error?)
    
}

extension MKFirestoreListener {
    func handle(_ changes: [DocumentChange]?, error: Error?) {
        guard let changes else {
            handle(nil, error: error)
            return
        }
        for change in changes {
            handle(change, error: nil)
        }
    }
}

public class MKFirestoreCollectionListener<Query: MKFirestoreCollectionQuery>: ObservableObject, Identifiable {
    public typealias AdditionalChangeHandler = (Query.BaseResultData) async ->Query.BaseResultData?
    public typealias ErrorHandler = (Error)->Void

    // Listener Registration
    public let id: String = UUID().uuidString
    private var listenerRegistration: ListenerRegistration?
    public var isListening: Bool {
        return listenerRegistration != nil
    }

    @Published public var didFinishInitialLoad: Bool = false
    @Published public var objects: [Query.BaseResultData] = []
    var query: Query
    private let firestore: MKFirestore
    
    // Handler
    public var onDidFinishInitialLoading: (()->Void)?
    public var onAddedAdditionalHandler: AdditionalChangeHandler?
    public var onModifiedAdditionalHandler: AdditionalChangeHandler?
    public var onRemovedAdditionalHandler: AdditionalChangeHandler?
    public var onErrorHandler: ErrorHandler?
    
    private var isMockedListener: Bool {
        return firestore is MKFirestoreMock
    }
    
    public var onAddedOrModifiedProcessor: ((Query.BaseResultData) async -> Query.BaseResultData)?
    
    // MARK: - Init
    public init(query: Query,
                firestore: MKFirestore,
                onDidFinishInitialLoading: (()->Void)? = nil,
                onAddedAdditionalHandler: AdditionalChangeHandler? = nil,
                onModifiedAdditionalHandler: AdditionalChangeHandler? = nil,
                onRemovedAdditionalHandler: AdditionalChangeHandler? = nil,
                onErrorHandler: ErrorHandler? = nil
    ) {
        self.query = query
        self.firestore = firestore
        self.onDidFinishInitialLoading = onDidFinishInitialLoading
        self.onAddedAdditionalHandler = onAddedAdditionalHandler
        self.onModifiedAdditionalHandler = onModifiedAdditionalHandler
        self.onRemovedAdditionalHandler = onRemovedAdditionalHandler
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

    public func onAdded(_ object: Query.BaseResultData, _ query: Query) {
        guard isListening else { return }
        Task {
            var newObject: Query.BaseResultData? = object
            if let onAddedAdditionalHandler {
                newObject = await onAddedAdditionalHandler(object)
            }
            
            guard let newObject else { return }
            
            if isMockedListener {
                guard isListening && query.isEqual(to: self.query) else { return }
                self.objects.append(newObject)
                self.publishInitialLoading()
            } else {
                DispatchQueue.main.async {
                    guard self.isListening && query.isEqual(to: self.query) else { return }
                    self.objects.append(newObject)
                    self.publishInitialLoading()
                }
            }
        }
    }
    
    public func onModified(_ object: Query.BaseResultData, _ query: Query) {
        guard isListening else { return }
        Task {
            var newObject: Query.BaseResultData? = object
            if let onModifiedAdditionalHandler {
                newObject = await onModifiedAdditionalHandler(object)
            }
            guard let newObject else { return }
            
            if isMockedListener {
                guard self.isListening && query.isEqual(to: self.query) else { return }
                if let index = self.objects.firstIndex(where: { $0.id == newObject.id }) {
                    self.objects[index] = newObject
                } else {
                    self.objects.append(newObject)
                }
            } else {
                DispatchQueue.main.async {
                    guard self.isListening && query.isEqual(to: self.query) else { return }
                    if let index = self.objects.firstIndex(where: { $0.id == newObject.id }) {
                        self.objects[index] = newObject
                    } else {
                        self.objects.append(newObject)
                    }
                    self.publishInitialLoading()
                }
            }
        }
    }
    
    public func onRemoved(_ object: Query.BaseResultData, _ query: Query) {
        guard isListening else { return }
        Task {
            var removedObject: Query.BaseResultData? = object
            if let onRemovedAdditionalHandler {
                removedObject = await onRemovedAdditionalHandler(object)
            }
            
            guard let removedObject else { return }
            
            if isMockedListener {
                guard isListening && query.isEqual(to: self.query) else { return }
                self.objects.removeAll(where: { $0.id == removedObject.id })
                self.publishInitialLoading()
            } else {
                DispatchQueue.main.async {
                    guard self.isListening && query.isEqual(to: self.query) else { return }
                    self.objects.removeAll(where: { $0.id == removedObject.id })
                    self.publishInitialLoading()
                }
            }
        }
    }
    
    private func publishInitialLoading() {
        if !didFinishInitialLoad {
            didFinishInitialLoad = true
            onDidFinishInitialLoading?()
        }
    }
    
    // MARK: - Universal change handler
    func handle(_ changes: [DocumentChange]?, error: Error?, for query: Query) {
        guard isListening && query.isEqual(to: self.query) else { return }
        if !didFinishInitialLoad && (changes?.isEmpty ?? true) {
            didFinishInitialLoad = true
            onDidFinishInitialLoading?()
        }
        guard let changes else {
            if let error { handle(error) }
            return
        }
        Task {
            var results = self.objects
            for change in changes {
                do {
                    let object = try change.document.data(as: Query.BaseResultData.self)
                    switch change.type {
                    case .added:
                        if let newObject = await onAddedFactory(object) {
                            results.append(newObject)
                            self.processOnAddedOrModifiedIfNeeded(on: newObject)
                        }
                    case .modified:
                        if let newObject = await onModifiedFactory(object) {
                            if let index = results.firstIndex(where: { $0.id == newObject.id }) {
                                results[index] = newObject
                            } else {
                                results.append(newObject)
                            }
                            self.processOnAddedOrModifiedIfNeeded(on: newObject)
                        }
                    case .removed:
                        if let newObject = await onModifiedFactory(object) {
                            results.removeAll(where: { $0.id == newObject.id })
                        }
                    }
                } catch {
                    handle(error)
                }
            }
            let finalResults = results
            print("$ MKFirestoreListener: processed \(changes.count) changes")
            DispatchQueue.main.async {
                self.objects = finalResults
                self.publishInitialLoading()
            }
        }
    }
    
    private func onAddedFactory(_ object: Query.BaseResultData) async -> Query.BaseResultData? {
        var newObject: Query.BaseResultData? = object
        if let onAddedAdditionalHandler {
            newObject = await onAddedAdditionalHandler(object)
        }
        return newObject
    }
    
    private func onModifiedFactory(_ object: Query.BaseResultData) async -> Query.BaseResultData? {
        var newObject: Query.BaseResultData? = object
        if let onModifiedAdditionalHandler {
            newObject = await onModifiedAdditionalHandler(object)
        }
        return newObject
    }
    
    private func onRemovedFactory(_ object: Query.BaseResultData) async -> Query.BaseResultData? {
        var newObject: Query.BaseResultData? = object
        if let onRemovedAdditionalHandler {
            newObject = await onRemovedAdditionalHandler(object)
        }
        return newObject
    }
    
    private func processOnAddedOrModifiedIfNeeded(on object: Query.BaseResultData) {
        guard let onAddedOrModifiedProcessor else { return }
        Task {
            let modifiedObject = await onAddedOrModifiedProcessor(object)
            DispatchQueue.main.async {
                if let index = self.objects.firstIndex(where: { $0.id == object.id }) {
                    self.objects[index] = modifiedObject
                }
            }
        }
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
