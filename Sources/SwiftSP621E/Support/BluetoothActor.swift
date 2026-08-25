//
//  BluetoothActor.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/17/26.
//

import Foundation
import CoreBluetooth

@globalActor public actor BluetoothActor: GlobalActor {
    public static let shared = BluetoothActor()
    
    public nonisolated let queue = DispatchSerialQueue(label: "SwiftSP621E.BluetoothActor")
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
}
