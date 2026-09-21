//
//  Device.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

import Foundation

/// A discovered, but not connected, SP621E SPI LED controller.
public struct DiscoveredSP621E: Codable, Identifiable, Equatable, Sendable, Hashable {
    /// An identifier that can be used to recognize controllers that have previously connected.
    public let id: UUID
    /// A user-configurable name for the controller.
    public var name: String
    /// The last known recieved signal strength indicator (RSSI) of the device.
    public var rssi: Int
    
    init(id: UUID, name: String, rssi: Int) {
        self.id = id
        self.name = name
        self.rssi = rssi
    }
}
