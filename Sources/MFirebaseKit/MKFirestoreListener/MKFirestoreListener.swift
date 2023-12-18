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

public class MKFirestoreCollectionListener<Query: MKFirestoreCollectionQuery>: ObservableObject {
    public typealias AdditionalChangeHandler = (Query.BaseResultData) async ->Query.BaseResultData?
    public typealias ErrorHandler = (Error)->Void

    // Listener Registration
    private var listenerRegistration: ListenerRegistration?
    public var isListening: Bool {
        return listenerRegistration != nil
    }

    @Published public var objects: [Query.BaseResultData] = []
    let query: Query
    private let firestore: MKFirestore
    
    // Handler
    private let onAddedAdditionalHandler: AdditionalChangeHandler?
    private let onModifiedAdditionalHandler: AdditionalChangeHandler?
    private let onRemovedAdditionalHandler: AdditionalChangeHandler?
    private let onErrorHandler: ErrorHandler?
    
    private var isMockedListener: Bool {
        return firestore is MKFirestoreMock
    }
    
    // MARK: - Init
    public init(query: Query,
         firestore: MKFirestore,
         onAddedAdditionalHandler: AdditionalChangeHandler? = nil,
         onModifiedAdditionalHandler: AdditionalChangeHandler? = nil,
         onRemovedAdditionalHandler: AdditionalChangeHandler? = nil,
         onErrorHandler: ErrorHandler? = nil
    ) {
        self.query = query
        self.firestore = firestore
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
    }
    
    // MARK: - Error Handling
    public func handle(_ error: Error) {
        // handle error
        onErrorHandler?(error)
    }
    
    // MARK: - Object change handling
    
    public func onAdded(_ object: Query.BaseResultData) {
        guard isListening else { return }
        Task {
            var newObject: Query.BaseResultData? = object
            if let onAddedAdditionalHandler {
                newObject = await onAddedAdditionalHandler(object)
            }
            
            guard let newObject else { return }
            
            if isMockedListener {
                self.objects.append(newObject)
            } else {
                DispatchQueue.main.async {
                    self.objects.append(newObject)
                }
            }
        }
    }
    
    public func onModified(_ object: Query.BaseResultData) {
        guard isListening else { return }
        Task {
            var newObject: Query.BaseResultData? = object
            if let onModifiedAdditionalHandler {
                newObject = await onModifiedAdditionalHandler(object)
            }
            guard let newObject else { return }
            
            if isMockedListener {
                if let index = self.objects.firstIndex(where: { $0.id == newObject.id }) {
                    self.objects[index] = newObject
                } else {
                    self.objects.append(newObject)
                }
            } else {
                DispatchQueue.main.async {
                    if let index = self.objects.firstIndex(where: { $0.id == newObject.id }) {
                        self.objects[index] = newObject
                    } else {
                        self.objects.append(newObject)
                    }
                }
            }
        }
    }
    
    public func onRemoved(_ object: Query.BaseResultData) {
        guard isListening else { return }
        Task {
            var removedObject: Query.BaseResultData? = object
            if let onRemovedAdditionalHandler {
                removedObject = await onRemovedAdditionalHandler(object)
            }
            
            guard let removedObject else { return }
            
            if isMockedListener {
                self.objects.removeAll(where: { $0.id == removedObject.id })
            } else {
                DispatchQueue.main.async {
                    self.objects.removeAll(where: { $0.id == removedObject.id })
                }
            }
        }
    }
    
    // MARK: - Universal change handler
    func handle(_ changes: [DocumentChange]?, error: Error?) {
        guard isListening else { return }
        guard let changes else {
            if let error { handle(error) }
            return
        }
        
        for change in changes {
            let changeHandler: (Query.BaseResultData)->Void
            
            switch change.type {
            case .added:
                changeHandler = onAdded(_:)
            case .modified:
                changeHandler = onModified(_:)
            case .removed:
                changeHandler = onRemoved(_:)
            }
            
            do {
                let object = try change.document.data(as: Query.BaseResultData.self)
                changeHandler(object)
            } catch {
                handle(error)
            }
        }
    }
}
