//
//  File.swift
//  
//
//  Created by Joschua Marz on 06.12.23.
//

import FirebaseFirestore

typealias VoidHandler = () -> Void

public class MockListenerRegistration: NSObject, ListenerRegistration {
    let onChange: VoidHandler
    let onRemove: VoidHandler
    
    init(
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
    
    // MARK: - Universal change handler
    func handle(_ changes: [DocumentChange]?, error: Error?, for query: Query) {
        guard isListening && query.isEqual(to: self.query) else { return }
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
                        if let newObject = await processObjectIfNeeded(object) {
                            results.append(newObject)
                        }
                    case .modified:
                        if let newObject = await processObjectIfNeeded(object) {
                            if let index = results.firstIndex(where: { $0.id == newObject.id }) {
                                results[index] = newObject
                            } else {
                                results.append(newObject)
                            }
                        }
                    case .removed:
                        results.removeAll(where: { $0.id == object.id })
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
