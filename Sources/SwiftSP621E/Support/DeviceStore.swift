//
//  DeviceStore.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/21/26.
//

import Foundation
import os

/// A store of Bluetooth devices.
internal final class DeviceStore {
    private static let suiteName: String = "SwiftSP621E"
    private static let savedDevicesKey: String = "SavedDevices"
    
    private let defaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    
    /// The identifiers of persisted devices.
    internal private(set) var identifiers: [UUID] = []
    /// A boolean value indicating whether there are no persisted devices.
    internal var isEmpty: Bool { identifiers.isEmpty }
    /// The number of persisted devices.
    internal var deviceCount: Int { identifiers.count }
    
    internal init() {
        guard let data = self.defaults.data(forKey: Self.savedDevicesKey),
              let decodedIdentifiers = try? JSONDecoder().decode([UUID].self, from: data)
        else {
            Logger.persistence.info("Could not decode saved devices.")
            return
        }
        self.identifiers = decodedIdentifiers
    }
    
    /// Persists the specified devices.
    ///
    /// - Parameter devices: The devices to persist.
    internal func save(_ devices: [Device]) {
        for device in devices { self.identifiers.append(device.id) }
        if let data = try? JSONEncoder().encode(self.identifiers) {
            defaults.set(data, forKey: Self.savedDevicesKey)
        }
    }
    
    /// Forgets all persisted devices.
    internal func forgetDevices() {
        self.identifiers = []
        defaults.removeObject(forKey: Self.savedDevicesKey)
    }
}
