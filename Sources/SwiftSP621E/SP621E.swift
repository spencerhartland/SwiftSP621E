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
public final class SP621E: NSObject, Identifiable, Sendable {
    public enum Notification: Sendable {
        case connectionState(id: UUID, state: ConnectionState)
        case controllerState(id: UUID, state: State?)
    }
    
    private enum Command: Sendable {
        case connect
        case disconnect
        case queryState
        case powerOn(Bool)
        case setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8)
        case setBrightness(UInt8)
        case setEffect(SP621EEffect)
        case setEffectSpeed(UInt8)
        case setEffectLength(UInt8)
        case identify
        case changeName(String)
        case applyState(SP621E.State)
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
        public var effectID: UInt8
        /// The speed at which dynamic lighting effects are displayed by the controller.
        public var effectSpeed: UInt8
        /// The duration of a single loop in a dynamic lighting effect.
        public var effectLength: UInt8
        
        public init(
            isOn: Bool,
            brightness: UInt8,
            mode: SP621EMode,
            rgb: (red: UInt8, green: UInt8, blue: UInt8),
            effectID: UInt8,
            effectSpeed: UInt8,
            effectLength: UInt8,
        ) {
            self.isOn = isOn
            self.brightness = brightness
            self.mode = mode
            self.rgb = RGB(red: rgb.red, green: rgb.green, blue: rgb.blue)
            self.effectID = effectID
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
            self.mode = bytes[7] == SP621EEffect.none.id ? .solidColor : .dynamicEffect
            self.rgb = RGB(red: bytes[12], green: bytes[13], blue: bytes[14])
            self.effectID = bytes[7]
            self.effectSpeed = bytes[10]
            self.effectLength = bytes[11]
        }
    }
    
    public static let defaultName: String = "SP621E"
    public nonisolated static let controllerNameCharacterLimit: Int = 10
    public nonisolated static let effectSpeedRange: ClosedRange<Double> = 1...10
    public nonisolated static let effectLengthRange: ClosedRange<Double> = 1...150
    
    private let notificationsContinuation: AsyncStream<Notification>.Continuation
    
    private let commands: AsyncStream<Command>
    private let commandsContinuation: AsyncStream<Command>.Continuation
    
    /// The peripheral associated with the controller.
    public let peripheral: CBPeripheral
    
    /// The unique identifier of the controller.
    public var id: UUID { peripheral.identifier }
    
    /// The name of the controller.
    public var name: String
    
    /// The connection state of the controller.
    public private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            notificationsContinuation.yield(.connectionState(id: id, state: connectionState))
        }
    }
    
    /// The internal state of the controller.
    public private(set) var state: SP621E.State? {
        didSet { notificationsContinuation.yield(.controllerState(id: id, state: state)) }
    }
    
    private var writeableCharacteristic: CBCharacteristic?
    private var pendingWrites: [[UInt8]] = []

    public init(
        peripheral: CBPeripheral,
        notifications continuation: AsyncStream<Notification>.Continuation
    ) {
        self.name = peripheral.name ?? Self.defaultName
        self.peripheral = peripheral
        
        self.notificationsContinuation = continuation
        (self.commands, self.commandsContinuation) = AsyncStream.makeStream()
        
        super.init()
        
        Task { @BluetoothActor in
            for await command in commands {
                handleCommand(command)
            }
        }
    }
    
    // MARK: Low-level Communication -
    
    private func sendCommand(
        for opcode: Bluetooth.Opcode,
        withBytes bytes: [UInt8],
        withResponse: Bool = false
    ) {
        let byteCount = UInt8(bytes.count)
        let commandHeader: [UInt8] = [Bluetooth.frameHeader, opcode.rawValue, byteCount]
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
        for service in services where service.uuid == Bluetooth.primaryServiceUUID {
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
        flushPending()
    }
}

// MARK: Public Methods -

extension SP621E {
    public nonisolated func connect() { commandsContinuation.yield(.connect) }
    
    public nonisolated func disconnect() { commandsContinuation.yield(.disconnect) }

    // MARK: Commands -
    
    /// Request the controller's current state.
    public nonisolated func queryState() { commandsContinuation.yield(.queryState) }
    
    /// Power on the LEDs connected to the controller.
    public nonisolated func powerOn() { commandsContinuation.yield(.powerOn(true)) }
    
    /// Power off the LEDs connected to the controller.
    public nonisolated func powerOff() { commandsContinuation.yield(.powerOn(false)) }

    /// Set the LEDs connected to the controller to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the controller.
    public nonisolated func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        commandsContinuation.yield(
            .setColor(red: red, green: green, blue: blue, brightness: brightness)
        )
    }

    /// Set the brightness of the LEDs connected to the controller.
    ///
    /// - Parameter value: The desired brightness.
    public nonisolated func setBrightness(_ value: UInt8) {
        commandsContinuation.yield(.setBrightness(value))
    }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    public nonisolated func setEffect(_ effect: SP621EEffect) {
        commandsContinuation.yield(.setEffect(effect))
    }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    public nonisolated func setEffectSpeed(_ speed: UInt8) {
        commandsContinuation.yield(.setEffectSpeed(speed))
    }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    public nonisolated func setEffectLength(_ length: UInt8) {
        commandsContinuation.yield(.setEffectLength(length))
    }
    
    /// 
    public nonisolated func identify() { commandsContinuation.yield(.identify) }
    
    /// Change the name of the controller.
    ///
    /// - Parameter name: The new name for the controller.
    public nonisolated func changeName(to name: String) throws {
        guard name.count <= Self.controllerNameCharacterLimit else {
            throw SP621EError.nameExceedsCharacterLimit
        }
        commandsContinuation.yield(.changeName(name))
    }
    
    /// Applies the specified state to the controller.
    ///
    /// - Parameter state: The desired state of the controller.
    public nonisolated func applyState(_ state: SP621E.State) {
        commandsContinuation.yield(.applyState(state))
    }
}

// MARK: Command Handling -

extension SP621E {
    private func handleCommand(_ command: Command) {
        switch command {
        case .connect:
            handleConnect()
        case .disconnect:
            handleDisconnect()
        case .queryState:
            handleQueryState()
        case .powerOn(let isOn):
            handlePowerOn(isOn)
        case .setColor(let red, let green, let blue, let brightness):
            handleSetColor(red: red, green: green, blue: blue, brightness: brightness)
        case .setBrightness(let brightness):
            handleSetBrightness(brightness)
        case .setEffect(let effect):
            handleSetEffect(effect)
        case .setEffectSpeed(let speed):
            handleSetEffectSpeed(speed)
        case .setEffectLength(let length):
            handleSetEffectLength(length)
        case .identify:
            handleIdentify()
        case .changeName(let newName):
            handleNameChange(to: newName)
        case .applyState(let state):
            handleApplyState(state)
        }
    }
    
    private func handleConnect() {
        peripheral.delegate = self
        peripheral.discoverServices([Bluetooth.primaryServiceUUID])
    }
    
    private func handleDisconnect() {
        writeableCharacteristic = nil
        connectionState = .disconnected
    }
    
    private func handleQueryState() { sendCommand(for: .queryState, withBytes: [0x00]) }
    
    private func handlePowerOn(_ isOn: Bool) {
        if isOn {
            sendCommand(for: .power, withBytes: [0x01])
        } else {
            sendCommand(for: .power, withBytes: [0x00])
        }
    }
    
    private func handleSetColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        sendCommand(for: .color, withBytes: [red, green, blue, brightness])
    }
    
    private func handleSetBrightness(_ brightness: UInt8) {
        sendCommand(for: .brightness, withBytes: [brightness])
    }
    
    private func handleSetEffect(_ effect: SP621EEffect) {
        sendCommand(for: .effect, withBytes: [effect.id])
    }
    
    private func handleSetEffectSpeed(_ speed: UInt8) {
        sendCommand(for: .effectSpeed, withBytes: [speed])
    }
    
    private func handleSetEffectLength(_ length: UInt8) {
        sendCommand(for: .effectLength, withBytes: [length])
    }
    
    private func handleIdentify() {
        let powerOn = self.state?.isOn ?? true
        
        Task {
            defer { powerOn ? self.powerOn() : self.powerOff() }
            
            for _ in 0...1 {
                powerOn ? self.powerOff() : self.powerOn()
                try? await Task.sleep(for: .seconds(0.5))
                powerOn ? self.powerOn() : self.powerOff()
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
    }
    
    private func handleNameChange(to name: String) {
        self.name = name
        sendCommand(for: .rename, withBytes: [UInt8](name.utf8), withResponse: true)
    }
    
    private func handleApplyState(_ state: SP621E.State) {
        sendCommand(for: .brightness, withBytes: [state.brightness], withResponse: true)

        switch state.mode {
        case .solidColor:
            sendCommand(
                for: .effect,
                withBytes: [SP621EEffect.none.id],
                withResponse: true
            )
            sendCommand(
                for: .color,
                withBytes: [state.rgb.red, state.rgb.green, state.rgb.blue, state.brightness],
                withResponse: true
            )
        case .dynamicEffect:
            sendCommand(for: .effect, withBytes: [state.effectID], withResponse: true)
            sendCommand(for: .effectSpeed, withBytes: [state.effectSpeed], withResponse: true)
            sendCommand(
                for: .effectLength,
                withBytes: [state.effectLength],
                withResponse: true
            )
        case .audio:
            sendCommand(for: .effect, withBytes: [state.effectID], withResponse: true)
        }
        
        sendCommand(for: .power, withBytes: [state.isOn ? 0x01 : 0x00], withResponse: true)
    }
}
