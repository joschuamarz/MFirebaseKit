//
//  File.swift
//  
//
//  Created by Joschua Marz on 30.04.24.
//

import Foundation
import FirebaseFirestore
import MFirebaseKitFirestoreCore

class MKFirestoreListenerRegistration: MKListenerRegistration {
    private let registration: ListenerRegistration

    init(registration: ListenerRegistration) {
        self.registration = registration
    }
    
    func remove() {
        registration.remove()
    }
}
