//
//  BluetoothActor.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/17/26.
//

import Foundation

@globalActor public actor BluetoothActor: GlobalActor {
    public static let shared = BluetoothActor()
    
    nonisolated let queue = DispatchSerialQueue(label: "SwiftSP621E.BluetoothActor")
    
    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
}
