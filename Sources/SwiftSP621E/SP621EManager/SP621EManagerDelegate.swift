//
//  SP621EManagerDelegate.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

import Foundation

@BluetoothActor
public protocol SP621EManagerDelegate: AnyObject {
    func sp621eManagerDidUpdatePairingState(_ manager: SP621EManager)
    func sp621eManagerDidUpdateConnectionState(_ manager: SP621EManager)
    func sp621eManagerDidUpdateControllerState(_ manager: SP621EManager)
    func sp621eManager(_ manager: SP621EManager, didDiscover device: Device)
    func sp621eManager(_ manager: SP621EManager, didConnectController id: UUID, name: String)
    func sp621eManager(_ manager: SP621EManager, didRenameController id: UUID, to name: String)
    func requestedControllerState() async -> SP621E.State
}
