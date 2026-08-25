//
//  Device.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

import Foundation

/// A bluetooth device.
public struct Device: Codable, Identifiable, Equatable, Sendable, Hashable {
    /// An identifier that can be used to recognize devices that have previously connected.
    public let id: UUID
    /// A user-configurable name for the device.
    public var name: String
    /// The last known recieved signal strength indicator (RSSI) of the device.
    public var rssi: Int
    
    init(id: UUID, name: String, rssi: Int) {
        self.id = id
        self.name = name
        self.rssi = rssi
    }
}
