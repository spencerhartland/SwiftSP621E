//
//  SP621EDelegate.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

@BluetoothActor
public protocol SP621EDelegate: AnyObject {
    func sp621eDidUpdateConnectionState(_ controller: SP621E)
    func sp621eDidUpdateState(_ controller: SP621E)
}
