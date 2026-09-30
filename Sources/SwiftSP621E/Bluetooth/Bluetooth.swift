//
//  Bluetooth.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/24/26.
//

import CoreBluetooth

internal enum Bluetooth {
    static let manufacturerPrefix: [UInt8] = [0x53, 0x50, 0x0D, 0x10, 0x59, 0x28, 0xEA, 0xA7]
    static let frameHeader: UInt8 = 0xA0
    static var advertisedServiceUUID: CBUUID { CBUUID(string: "E0FF") }
    static var primaryServiceUUID: CBUUID { CBUUID(string: "FFE0") }
    static var characteristicUUID: CBUUID { CBUUID(string: "FFE1") }
    
    enum Opcode: UInt8 {
        case power = 0x62
        case brightness = 0x66
        case color = 0x69
        case effect = 0x63
        case effectSpeed = 0x67
        case effectLength = 0x68
        case audioSensitivity = 0x6B
        case queryState = 0x70
        case rename = 0x61
        case audioFrame = 0x6D
    }
}
