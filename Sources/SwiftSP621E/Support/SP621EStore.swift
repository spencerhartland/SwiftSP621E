//
//  DeviceStore.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/21/26.
//

import Foundation
import os

/// A store of Bluetooth devices.
internal final class SP621EStore {
    private static let suiteName: String = "SwiftSP621E"
    private static let savedControllersKey: String = "SavedControllers"
    
    private let defaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    
    /// The identifiers of persisted devices.
    internal private(set) var identifiers: [UUID] = []
    /// A boolean value indicating whether there are no persisted devices.
    internal var isEmpty: Bool { identifiers.isEmpty }
    /// The number of persisted devices.
    internal var deviceCount: Int { identifiers.count }
    
    internal init() {
        guard let data = self.defaults.data(forKey: Self.savedControllersKey),
              let decodedIdentifiers = try? JSONDecoder().decode([UUID].self, from: data)
        else {
            Logger.persistence.info("Could not decode saved controllers.")
            return
        }
        self.identifiers = decodedIdentifiers
    }
    
    /// Persists the specified controllers.
    ///
    /// - Parameter controllers: The controllers to persist.
    internal func saveControllers(_ controllers: [DiscoveredSP621E]) {
        let controllerIDs = controllers.map { $0.id }
        self.identifiers.append(contentsOf: controllerIDs)
        
        save()
    }
    
    /// Forgets all saved controllers.
    internal func forgetControllers(with identifiers: [UUID]? = nil) {
        if let identifiers {
            self.identifiers.removeAll { identifiers.contains([$0]) }
            save()
        } else {
            self.identifiers = []
            defaults.removeObject(forKey: Self.savedControllersKey)
        }
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(self.identifiers) else { return }
        defaults.set(data, forKey: Self.savedControllersKey)
    }
}
