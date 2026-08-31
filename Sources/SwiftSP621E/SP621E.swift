//
//  SP621E.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/12/26.
//

import Foundation
import CoreBluetooth

/// An SP621E SPI LED controller.
@BluetoothActor
public final class SP621E: NSObject, Identifiable {
    public enum Notification: Sendable {
        case connectionState(id: UUID, state: ConnectionState)
        case controllerState(id: UUID, state: State?)
    }
    
    /// The user-configured state of the controller.
    public struct State: Equatable, Sendable {
        /// A boolean value indicating whether or not the LEDs connected to the controller are
        /// receiving power.
        public var isOn: Bool
        /// The brightness value of the LEDs connected to the controller.
        public var brightness: UInt8
        /// The current `Mode` in which the controller is operating.
        public var mode: SP621EMode
        /// The RGB values representing the current color of the LEDs connected to the controller.
        public var rgb: RGB
        /// The index of one of the controller's built-in dynamic lighting effects.
        public var effectIndex: UInt8
        /// The speed at which dynamic lighting effects are displayed by the controller.
        public var effectSpeed: UInt8
        /// The duration of a single loop in a dynamic lighting effect.
        public var effectLength: UInt8
        
        public init(
            isOn: Bool,
            brightness: UInt8,
            mode: SP621EMode,
            rgb: (red: UInt8, green: UInt8, blue: UInt8),
            effectIndex: UInt8,
            effectSpeed: UInt8,
            effectLength: UInt8,
        ) {
            self.isOn = isOn
            self.brightness = brightness
            self.mode = mode
            self.rgb = RGB(red: rgb.red, green: rgb.green, blue: rgb.blue)
            self.effectIndex = effectIndex
            self.effectSpeed = effectSpeed
            self.effectLength = effectLength
        }
        
        internal init?(from bytes: [UInt8]) {
            // Expect length of 20 bytes, header 0x53 0x43, frame index 0x01.
            guard bytes.count == 20, bytes[0] == 0x53, bytes[1] == 0x43, bytes[2] == 0x01 else {
                return nil
            }
            
            self.isOn = bytes[5] == 0x01
            self.brightness = bytes[9]
            self.mode = bytes[7] == SP621EEffect.none.rawValue ? .solidColor : .dynamicEffect
            self.rgb = RGB(red: bytes[12], green: bytes[13], blue: bytes[14])
            self.effectIndex = bytes[7]
            self.effectSpeed = bytes[10]
            self.effectLength = bytes[11]
        }
    }
    
    private static let controllerNameCharacterLimit: Int = 10
    
    /// The peripheral associated with the controller.
    public let peripheral: CBPeripheral
    
    /// The UUID associated with the controller.
    public var id: UUID { peripheral.identifier }
    
    private let notificationsContinuation: AsyncStream<Notification>.Continuation
    
    /// The connection state of the controller.
    public private(set) var connectionState: ConnectionState = .disconnected {
        didSet { notificationsContinuation.yield(.connectionState(id: id, state: connectionState)) }
    }
    
    public private(set) var state: SP621E.State? {
        didSet { notificationsContinuation.yield(.controllerState(id: id, state: state)) }
    }
    
    private var writeableCharacteristic: CBCharacteristic?
    private var pendingWrites: [[UInt8]] = []

    public init(peripheral: CBPeripheral, notifications continuation: AsyncStream<Notification>.Continuation) {
        self.peripheral = peripheral
        self.notificationsContinuation = continuation
        super.init()
    }
    
    /// Handles peripheral connection.
    ///
    /// Call from `centralManager(_:didConnect:)` to begin discovering the services and
    /// characteristics of the controller.
    public func connect() {
        peripheral.delegate = self
        peripheral.discoverServices([Bluetooth.serviceUUID])
    }
    
    /// Handles peripheral disconnection.
    ///
    /// Call from `centralManager(_:didFailToConnect:error:)` and
    /// `centralManager(_:didDisconnectPeripheral:error:)` to update state following disconnect.
    public func disconnect() {
        writeableCharacteristic = nil
        connectionState = .disconnected
    }

    // MARK: Commands -
    
    /// Request the controller's current state.
    public func queryState() { sendCommand(for: .queryState, withBytes: [0x00]) }
    
    /// Power on the LEDs connected to the controller.
    public func powerOn() { sendCommand(for: .power, withBytes: [0x01]) }
    
    /// Power off the LEDs connected to the controller.
    public func powerOff() { sendCommand(for: .power, withBytes: [0x00]) }

    /// Set the LEDs connected to the controller to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the controller.
    public func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        sendCommand(for: .color, withBytes: [red, green, blue, brightness])
    }

    /// Set the brightness of the LEDs connected to the controller.
    ///
    /// - Parameter value: The desired brightness.
    public func setBrightness(_ value: UInt8) {
        sendCommand(for: .brightness, withBytes: [value])
    }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    public func setEffect(_ effect: SP621EEffect) {
        sendCommand(for: .effect, withBytes: [effect.rawValue])
    }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    public func setEffectSpeed(_ speed: UInt8) {
        sendCommand(for: .effectSpeed, withBytes: [speed])
    }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    public func setEffectLength(_ length: UInt8) {
        sendCommand(for: .effectLength, withBytes: [length])
    }
    
    /// Change the name of the controller.
    ///
    /// - Parameter name: The name the controller advertises over Bluetooth.
    public func rename(to name: String) throws {
        guard name.count <= Self.controllerNameCharacterLimit else {
            throw SP621EError.nameExceedsCharacterLimit
        }
        sendCommand(for: .rename, withBytes: [UInt8](name.utf8), withResponse: true)
    }
    
    /// Applies the specified state to the controller.
    ///
    /// - Parameter state: The desired state of the controller.
    public func applyState(_ state: SP621E.State) {
        sendCommand(for: .brightness, withBytes: [state.brightness], withResponse: true)

        switch state.mode {
        case .solidColor:
            sendCommand(for: .effect, withBytes: [SP621EEffect.none.rawValue], withResponse: true)
            sendCommand(
                for: .color,
                withBytes: [state.rgb.red, state.rgb.green, state.rgb.blue, state.brightness],
                withResponse: true
            )
        case .dynamicEffect:
            sendCommand(for: .effect, withBytes: [state.effectIndex], withResponse: true)
            sendCommand(for: .effectSpeed, withBytes: [state.effectSpeed], withResponse: true)
            sendCommand(for: .effectLength, withBytes: [state.effectLength], withResponse: true)
        }
        
        sendCommand(for: .power, withBytes: [state.isOn ? 0x01 : 0x00], withResponse: true)
    }
    
    // MARK: Low-level Communication -
    
    private func sendCommand(
        for opcode: Bluetooth.Opcode,
        withBytes bytes: [UInt8],
        withResponse: Bool = false
    ) {
        let commandHeader: [UInt8] = [Bluetooth.frameHeader, opcode.rawValue, UInt8(bytes.count)]
        let command: [UInt8] = commandHeader + bytes
        send(command, withResponse: withResponse)
    }
    
    private func send(_ bytes: [UInt8], withResponse: Bool = false) {
        guard let writeableCharacteristic else {
            self.pendingWrites.append(bytes)
            return
        }
        let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
        if withResponse || self.peripheral.canSendWriteWithoutResponse {
            self.peripheral.writeValue(
                Data(bytes),
                for: writeableCharacteristic,
                type: type
            )
        } else {
            self.pendingWrites.append(bytes)
        }
    }

    private func flushPending() {
        guard let writeableCharacteristic else { return }
        while !pendingWrites.isEmpty, peripheral.canSendWriteWithoutResponse {
            let data = Data(pendingWrites.removeFirst())
            peripheral.writeValue(data, for: writeableCharacteristic, type: .withoutResponse)
        }
    }
}

// MARK: CBPeripheralDelegate -

extension SP621E: CBPeripheralDelegate {
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == Bluetooth.serviceUUID {
            peripheral.discoverCharacteristics([Bluetooth.characteristicUUID], for: service)
        }
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == Bluetooth.characteristicUUID {
            writeableCharacteristic = characteristic
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            connectionState = .connected
            flushPending()
        }
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == Bluetooth.characteristicUUID,
                let data = characteristic.value else { return }
        let bytes = [UInt8](data)
        guard let deviceState = State(from: bytes) else {
            return
        }
        self.state = deviceState
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil else { return }
        if characteristic.isNotifying { queryState() }
    }
    
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("peripheralIsReady — draining \(pendingWrites.count) pending")
        flushPending()
    }
}
