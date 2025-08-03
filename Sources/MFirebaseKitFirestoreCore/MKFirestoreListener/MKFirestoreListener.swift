//
//  File.swift
//  
//
//  Created by Joschua Marz on 06.12.23.
//

import Foundation
import Combine

public typealias VoidHandler = () -> Void


/// A generic class that listens to a Firestore collection using the provided query,
/// decoding document changes into typed Swift objects and publishing updates.
///
/// `MKFirestoreCollectionListener` observes real-time updates from Firestore and
/// exposes lifecycle callbacks as well as a published map of decoded documents.
/// It's designed to be reused with different queries and integrates easily into
/// SwiftUI via `@Published`.
///
/// - Note: This class is designed to work with Firestore via `MKFirestore` and uses Combine publishers.
public class MKFirestoreCollectionListener<Query: MKFirestoreCollectionQuery>: MKObservableService, Identifiable {
    
    // MARK: - Typealiases
    
    /// A closure that handles errors emitted during listening or decoding.
    public typealias ErrorHandler = (Error) -> Void
    
    /// A closure that receives a decoded object after it's added, modified, or removed.
    public typealias ChangeHandler = (Query.BaseResultData) -> Void

    // MARK: - Public Properties
    
    /// Uniquely identifies this listener instance.
    public let id: String = UUID().uuidString

    /// Indicates whether the listener is currently registered to a Firestore collection.
    public var isListening: Bool { listenerRegistration != nil }
    
    /// Whether the initial data load for the query has completed.
    ///
    /// This becomes `true` once the first snapshot has been processed.
    @Published public var didFinishInitialLoad: Bool = false
    
    /// A dictionary mapping document IDs to their decoded Swift objects.
    ///
    /// - Note: This property is published and read-only externally.
    @Published private(set) public var objectIdMap: [String: Query.BaseResultData] = [:]
    
    /// An array of all decoded objects in the collection.
    public var objects: [Query.BaseResultData] {
        return objectIdMap.map { $0.value }
    }

    /// The current query associated with this listener.
    public var query: Query

    /// A closure called once the initial snapshot from Firestore has been processed.
    public var onDidFinishInitialLoading: (() -> Void)?
    
    /// A closure called whenever an error occurs during listening or decoding.
    public var onError: ErrorHandler?
    
    /// A closure called when a new object is added to the collection.
    public var onAdded: ChangeHandler?
    
    /// A closure called when an existing object is modified in the collection.
    public var onModified: ChangeHandler?
    
    /// A closure called when an object is removed from the collection.
    public var onRemoved: ChangeHandler?

    // MARK: - Private Properties
    
    /// The active Firestore listener registration.
    ///
    /// This is non-nil only while listening to a collection.
    private var listenerRegistration: MKListenerRegistration?
    
    /// A reference to the Firestore abstraction responsible for executing queries.
    private let firestore: MKFirestore

    // MARK: - Initializers
    
    /// Initializes a new collection listener with full lifecycle callbacks.
    ///
    /// - Parameters:
    ///  - query: The query describing which collection to observe.
    ///  - firestore: The Firestore wrapper responsible for executing the query.
    ///  - onDidFinishInitialLoading: A closure called after the initial snapshot is loaded.
    ///  - onError: A closure called on error.
    ///  - onAdded: A closure called when a new object is added.
    ///  - onModified: A closure called when an object is modified.
    ///  - onRemoved: A closure called when an object is removed.
    ///
    ///  - Important: Does not automatically start listening to the provided query unless ``startListening()`` is called.
    public init(
        query: Query,
        firestore: MKFirestore,
        onDidFinishInitialLoading: VoidHandler? = nil,
        onError: ErrorHandler? = nil,
        onAdded: ChangeHandler? = nil,
        onModified: ChangeHandler? = nil,
        onRemoved: ChangeHandler? = nil
    ) {
        self.query = query
        self.firestore = firestore
        self.onDidFinishInitialLoading = onDidFinishInitialLoading
        self.onError = onError
        self.onAdded = onAdded
        self.onModified = onModified
        self.onRemoved = onRemoved
        super.init()
    }
    
    /// Convenience initializer for when added and modified objects share the same handling logic.
    ///
    /// - Parameters:
    ///  - query: The query describing which collection to observe.
    ///  - firestore: The Firestore wrapper responsible for executing the query.
    ///  - onDidFinishInitialLoading: A closure called after the initial snapshot is loaded.
    ///  - onError: A closure called on error.
    ///  - onAddedOrModified: A closure called on both added and modified events.
    ///  - onRemoved: A closure called when an object is removed.
    ///
    ///  - Important: Does not automatically start listening to the provided query unless ``startListening()`` is called.
    public convenience init(
        query: Query,
        firestore: MKFirestore,
        onDidFinishInitialLoading: VoidHandler? = nil,
        onError: ErrorHandler? = nil,
        onAddedOrModified: ChangeHandler? = nil,
        onRemoved: ChangeHandler? = nil
    ) {
        self.init(
            query: query,
            firestore: firestore,
            onDidFinishInitialLoading: onDidFinishInitialLoading,
            onError: onError,
            onAdded: onAddedOrModified,
            onModified: onAddedOrModified,
            onRemoved: onRemoved
        )
    }

    // MARK: - Public Methods

    /// Starts listening to the Firestore collection using the provided query.
    ///
    /// Does nothing if already listening.
    public func startListening() {
        guard !isListening else { return }
        listenerRegistration = firestore.addCollectionListener(self)
    }

    /// Stops listening to the Firestore collection and clears any loaded data.
    public func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        objectIdMap.removeAll()
        didFinishInitialLoad = false
    }

    /// Replaces the current query and stops listening to the previous one.
    ///
    /// - Parameter newQuery: The new query to use for listening.
    /// - Important: Does not automatically start listening to the new query unless ``startListening()`` is called.
    public func replaceQuery(with newQuery: Query) {
        stopListening()
        self.query = newQuery
    }

    /// Returns a previously loaded object for the given document ID, if available.
    ///
    /// - Parameter id: The document ID.
    /// - Returns: The decoded object, or `nil` if not found.
    public func getObject(by id: String) -> Query.BaseResultData? {
        return objectIdMap[id]
    }

    /// Invokes the error handler with the provided error.
    ///
    /// - Parameter error: The error to handle.
    public func handle(_ error: Error) {
        onError?(error)
    }

    // MARK: - Internal Logic

    /// Publishes the initial loading completion state.
    ///
    /// This is only called once per lifecycle.
    private func publishInitialLoading() {
        guard !didFinishInitialLoad else { return }
        didFinishInitialLoad = true
        onDidFinishInitialLoading?()
    }

    /// Processes incoming document changes from Firestore.
    ///
    /// - Parameters:
    ///   - changes: An array of document change descriptors.
    ///   - error: An optional error value if decoding or fetching failed.
    ///   - query: The query associated with the update.
    @MainActor
    public func handle(_ changes: [MKDocumentChange]?, error: Error?, for query: Query) {
        guard isListening && query.isEqual(to: self.query) else { return }
        
        if let error {
            handle(error)
            return
        }

        guard let changes else { return }

        for change in changes {
            do {
                let object = try change.object(as: Query.BaseResultData.self)
                let key = "\(object.id)"
                switch change.changeType {
                case .added:
                    objectIdMap[key] = object
                    onAdded?(object)
                case .modified:
                    objectIdMap[key] = object
                    onModified?(object)
                case .removed:
                    if let object = objectIdMap.removeValue(forKey: key) {
                        onRemoved?(object)
                    }
                }
            } catch {
                onError?(error)
            }
        }

        publishInitialLoading()
    }
}
