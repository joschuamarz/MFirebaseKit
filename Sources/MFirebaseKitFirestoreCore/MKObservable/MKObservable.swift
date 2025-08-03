//
//  File.swift
//  MFirebaseKit
//
//  Created by Joschua Marz on 02.08.25.
//

import Foundation
import Combine

public protocol MKObserver: ObservableObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

open class MKObservableService: ObservableObject {
    var cancellables: [ObjectIdentifier: AnyCancellable] = [:]
    
    public init() {}
    
    public func register(observer: any MKObserver, debounce seconds: Double = 0) {
        let cancellable = self.objectWillChange
            .debounce(for: .seconds(seconds), scheduler: RunLoop.main)
            .sink { (_) in
            observer.objectWillChange.send()
        }
        cancellables.updateValue(cancellable, forKey: ObjectIdentifier(observer))
    }
    
    public func register(observer: NSObject, debounce seconds: Double = 0, onChange: @escaping () -> Void) {
        let cancellable = self.objectWillChange
            .debounce(for: .seconds(seconds), scheduler: RunLoop.main)
            .sink { _ in
                onChange()
            }
        cancellables.updateValue(cancellable, forKey: ObjectIdentifier(observer))
    }
    
    public func remove(observer: NSObject) {
        if let cancellable = cancellables.removeValue(forKey: ObjectIdentifier(observer)) {
            cancellable.cancel()
        }
    }
}
