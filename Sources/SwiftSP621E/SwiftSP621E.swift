//
//  SwiftSP621E.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/29/26.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class SwiftSP621E {
    private let group = SP621EGroup()
    private var groupNotificationsTask: Task<Void, Never>?
    
    private var isUpdatingState: Bool = false
    
    /// The combined connection state of all controllers.
    public private(set) var connectionState: ConnectionState = .disconnected
    /// A boolean value indicating whether the combined connection state is `connected`.
    public var isConnected: Bool { connectionState == .connected }
    /// Discovered Bluetooth devices.
    public private(set) var discoveredDevices: [Device] = []
    /// Connected SP621E controllers.
    public private(set) var controllers: [UUID: String] = [:]
    /// A boolean value indicating whether pairing is complete.
    public private(set) var isPaired: Bool = false
    
    public var isOn: Bool = false {
        didSet {
            guard !isUpdatingState else { return }
            group.sendCommand(.power(isOn))
        }
    }
    public var brightness: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let value = UInt8(brightness.rounded())
            group.sendCommand(.setBrightness(value))
        }
    }
    public var mode: SP621EMode = .solidColor {
        didSet {
            guard !isUpdatingState else { return }
            switch mode {
            case .solidColor:
                effect = .none
            case .dynamicEffect:
                // TODO: When more modes are added, return to the last selected mode.
                effect = .rainbow
            }
        }
    }
    public var color: Color = Color(red: 255, green: 0, blue: 0) {
        didSet {
            guard !isUpdatingState else { return }
            let rgb = color.rgbBytes
            let brightnessValue = UInt8(brightness.rounded())
            group.sendCommand(
                .setColor(
                    red: rgb.red,
                    green: rgb.green,
                    blue: rgb.blue,
                    brightness: brightnessValue
                )
            )
        }
    }
    public var effect: SP621EEffect = .none {
        didSet {
            guard !isUpdatingState else { return }
            group.sendCommand(.setEffect(effect))
        }
    }
    public var effectSpeed: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let value = UInt8(effectSpeed.rounded())
            group.sendCommand(.setEffectSpeed(value))
        }
    }
    public var effectLength: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let value = UInt8(effectLength.rounded())
            group.sendCommand(.setEffectLength(value))
        }
    }
    
    public init() {
        self.groupNotificationsTask = Task { [weak self] in
            guard let self else { return }
            for await notification in self.group.notifications {
                handleGroupNotification(notification)
            }
        }
    }
    
    public func connect() { group.sendCommand(.connect) }
    
    public func pairDevices(_ devices: [Device]) { group.sendCommand(.pair(devices)) }
    
    public func forgetDevices() { group.sendCommand(.forget) }
    
    public func identifyController(with id: UUID, isOn: Bool) async throws {
        try await group.identifyController(with: id, isOn: isOn)
    }
    
    public func renameController(with id: UUID, to name: String) async throws {
        try await group.renameController(with: id, to: name)
    }
    
    private func handleGroupNotification(_ notification: SP621EGroup.Notification) {
        switch notification {
        case .connectionState(let connectionState):
            self.connectionState = connectionState
        case .isPaired(let pairingState):
            self.isPaired = pairingState
        case .controllerState(let state):
            self.handleControllerState(state)
        case .discoveredDevice(let device):
            self.discoveredDevices.append(device)
        case .connectedController(let id, let name):
            self.controllers[id] = name
        case .renamedController(let id, let name):
            self.controllers[id] = name
        }
    }
    
    private func handleControllerState(_ state: SP621E.State?) {
        guard let state else { return }
        self.isUpdatingState = true
        self.brightness = Double(state.brightness)
        self.color = state.rgb.color
        self.mode = state.mode
        if let effect = SP621EEffect(rawValue: state.effectIndex) { self.effect = effect }
        self.effectSpeed = Double(state.effectSpeed)
        self.effectLength = Double(state.effectLength)
        self.isOn = state.isOn
        self.isUpdatingState = false
    }
}
