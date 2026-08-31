//
//  SP621EGroup.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/15/26.
//

import Foundation
import CoreBluetooth
import os

/// Coordinates the behavior of one or more SP621E SPI LED controllers.
@BluetoothActor
public final class SP621EGroup: NSObject {
    public enum Notification: Sendable {
        case connectionState(ConnectionState)
        case isPaired(Bool)
        case controllerState(SP621E.State?)
        case discoveredDevice(Device)
        case connectedController(id: UUID, name: String)
        case renamedController(id: UUID, name: String)
    }
    
    public enum Command: Sendable {
        case connect
        case forget
        case pair([Device])
        case power(Bool)
        case setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8)
        case setBrightness(UInt8)
        case setEffect(SP621EEffect)
        case setEffectSpeed(UInt8)
        case setEffectLength(UInt8)
    }
    
    private static let defaultDeviceName: String = "SP621E"
    
    private var central: CBCentralManager!
    
    private let deviceStore = DeviceStore()
    private var expectedControllerCount: Int { deviceStore.deviceCount }
    private var discoveredControllers: Set<UUID> = []
    private var controllers: [UUID: SP621E] = [:]
    
    public nonisolated let notifications: AsyncStream<Notification>
    private let notificationsContinuation: AsyncStream<Notification>.Continuation
    
    private nonisolated let controllerNotifications: AsyncStream<SP621E.Notification>
    private let controllerNotificationsContinuation: AsyncStream<SP621E.Notification>.Continuation
    
    private let commands: AsyncThrottleSequence<AsyncStream<Command>, ContinuousClock, Command>
    private nonisolated let commandsContinuation: AsyncStream<Command>.Continuation
    
    private var primaryControllerID: UUID?
    private var controllerState: SP621E.State?
    
    private var isPaired: Bool = false {
        didSet { notificationsContinuation.yield(.isPaired(isPaired)) }
    }
    
    private var connectionState: ConnectionState = .disconnected {
        didSet { notificationsContinuation.yield(.connectionState(connectionState)) }
    }
    
    public nonisolated override init() {
        (self.notifications, self.notificationsContinuation) = AsyncStream.makeStream()
        (self.controllerNotifications, self.controllerNotificationsContinuation) = AsyncStream.makeStream()
        
        let (stream, continuation) = AsyncStream<Command>.makeStream()
        self.commands = stream.throttle(for: .milliseconds(80))
        self.commandsContinuation = continuation
        
        super.init()
        
        Task { @BluetoothActor in
            self.central = CBCentralManager(delegate: self, queue: BluetoothActor.shared.queue)
            
            async let controllerNotificationsTask: Void = {
                for await notification in controllerNotifications {
                    await handleControllerNotification(notification)
                }
            }()
            async let commandsTask: Void = {
                for await command in commands {
                    await handleCommand(command)
                }
            }()
            _ = await (commandsTask, controllerNotificationsTask)
        }
    }
    
    private func handleCommand(_ command: Command) {
        switch command {
        case .connect:
            connect()
        case .forget:
            forgetDevices()
        case .pair(let devices):
            pair(devices)
        case .power(let isOn):
            isOn ? powerOn() : powerOff()
        case .setColor(let red, let green, let blue, let brightness):
            setColor(red: red, green: green, blue: blue, brightness: brightness)
        case .setBrightness(let value):
            setBrightness(value)
        case .setEffect(let effect):
            setEffect(effect)
        case .setEffectSpeed(let speed):
            setEffectSpeed(speed)
        case .setEffectLength(let length):
            setEffectLength(length)
        }
    }
    
    public nonisolated func sendCommand(_ command: Command) { commandsContinuation.yield(command) }
    
    // MARK: Pairing and Connection -
    
    /// Connects to controllers.
    ///
    /// If paired controllers exist, the coordinator connects directly to them.  Otherwise, the
    /// coordinator begins searching and publishes a list of discovered devices
    private func connect() {
        guard self.central.state == .poweredOn,
              self.connectionState == .disconnected
        else {
            return
        }
        
        if self.deviceStore.isEmpty {
            self.searchForDevices()
        } else {
            self.connectPairedDevices()
        }
    }
    
    /// Pairs the specified devices.
    ///
    /// - Parameter devices: The devices to pair.
    private func pair(_ devices: [Device]) {
        guard !devices.isEmpty else { return }
        self.central.stopScan()
        self.deviceStore.save(devices)
        self.connectPairedDevices()
    }
    
    /// Forgets all paired devices.
    private func forgetDevices() {
        for controller in self.controllers.values {
            self.central.cancelPeripheralConnection(controller.peripheral)
        }
        self.controllers.removeAll()
        self.primaryControllerID = nil
        self.deviceStore.forgetDevices()
        self.searchForDevices()
    }
    
    private func searchForDevices() {
        self.isPaired = false
        self.connectionState = .connecting
        self.discoveredControllers.removeAll()
        central.scanForPeripherals(withServices: nil)
    }
    
    private func connectPairedDevices() {
        self.isPaired = true
        self.connectionState = .connecting
        
        let knownDevices = central.retrievePeripherals(withIdentifiers: deviceStore.identifiers)
        for peripheral in knownDevices {
            guard controllers[peripheral.identifier] == nil else { continue }
            handleConnectedController(peripheral)
            central.connect(peripheral)
        }
        
        let missingDevices = Set(deviceStore.identifiers).subtracting(controllers.keys)
        if !missingDevices.isEmpty {
            central.scanForPeripherals(withServices: nil)
        }
    }
    
    private func handleConnectedController(_ peripheral: CBPeripheral) {
        let controller = SP621E(
            peripheral: peripheral,
            notifications: controllerNotificationsContinuation
        )
        controllers[controller.id] = controller
    }
    
    private func handleControllerNotification(_ notification: SP621E.Notification) {
        switch notification {
        case .connectionState(_,_):
            self.updateConnectionState()
        case .controllerState(let id, let state):
            if primaryControllerID == nil {
                self.primaryControllerID = id
                self.controllerState = state
                notificationsContinuation.yield(.controllerState(state))
            } else {
                guard let controller = controllers[id] else { return }
                sync(controller)
            }
        }
    }
    
    // MARK: SP621E Commands -
    
    /// Power on the LEDs connected to the paired controllers.
    private func powerOn()  {
        forEachController { $0.powerOn() }
    }
    
    /// Power off the LEDs connected to the paired controllers.
    private func powerOff() {
        forEachController { $0.powerOff() }
    }
    
    /// Set the LEDs connected to the paired controllers to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the paired controllers.
    private func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        forEachController {
            $0.setColor(red: red, green: green, blue: blue, brightness: brightness)
        }
    }
    
    /// Set the brightness of the LEDs connected to the paired controllers.
    ///
    /// - Parameter value: The desired brightness.
    private func setBrightness(_ value: UInt8) {
        forEachController { $0.setBrightness(value) }
    }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    private func setEffect(_ effect: SP621EEffect) {
        forEachController { $0.setEffect(effect) }
    }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    private func setEffectSpeed(_ speed: UInt8) {
        forEachController { $0.setEffectSpeed(speed) }
    }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    private func setEffectLength(_ length: UInt8) {
        forEachController { $0.setEffectLength(length) }
    }
    
    public func identifyController(with id: UUID, isOn: Bool) async throws {
        guard let controller = controllers[id] else { throw SP621EError.controllerNotFound }
        for _ in 0...1 {
            isOn ? controller.powerOff() : controller.powerOn()
            try await Task.sleep(for: .seconds(0.5))
            isOn ? controller.powerOn() : controller.powerOff()
            try await Task.sleep(for: .seconds(0.5))
        }
    }
    
    /// Change the name of the controller with the specified identifier.
    ///
    /// - Parameters:
    ///     - id: The identifier of the controller to rename.
    ///     - name: The new name of the controller.
    public func renameController(with id: UUID, to name: String) async throws {
        guard let controller = controllers[id] else { throw SP621EError.controllerNotFound }
        try controller.rename(to: name)
        notificationsContinuation.yield(.renamedController(id: id, name: name))
    }
    
    private func forEachController(_ action: (SP621E) -> Void) {
        for controller in controllers.values {
            action(controller)
        }
    }
    
    // MARK: State management -
    
    private func updateConnectionState() {
        let connectedCount = controllers.values.filter { $0.connectionState == .connected }.count

        if expectedControllerCount > 0, connectedCount == expectedControllerCount {
            self.connectionState = .connected
        } else if connectedCount == 0 {
            self.connectionState = .disconnected
        } else {
            self.connectionState = .connecting
        }
        
        if controllers.values.allSatisfy({ $0.connectionState != .connected }) {
            self.primaryControllerID = nil
        }
    }
    
    private func sync(_ controller: SP621E) {
        guard let controllerState else { return }
        controller.applyState(controllerState)
    }
}

// MARK: CBCentralManagerDelegate -

extension SP621EGroup: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connect()
        default:
            connectionState = .disconnected
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let mfgPrefixLength = Bluetooth.manufacturerPrefix.count
        
        guard let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              mfgData.count >= mfgPrefixLength,
              mfgData.prefix(mfgPrefixLength).elementsEqual(Bluetooth.manufacturerPrefix)
        else {
            return
        }
        
        if isPaired {
            guard deviceStore.identifiers.contains(peripheral.identifier),
                  controllers[peripheral.identifier] == nil else {
                return
            }
            handleConnectedController(peripheral)
            central.connect(peripheral)
            
            let allDevicesConnected = Set(deviceStore.identifiers).isSubset(of: controllers.keys)
            if allDevicesConnected { central.stopScan() }
        } else {
            guard !discoveredControllers.contains(peripheral.identifier) else { return }
            discoveredControllers.insert(peripheral.identifier)
            
            let device = Device(
                id: peripheral.identifier,
                name: peripheral.name ?? Self.defaultDeviceName,
                rssi: RSSI.intValue
            )
            notificationsContinuation.yield(.discoveredDevice(device))
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        guard let controller = controllers[peripheral.identifier] else { return }
        controller.connect()
        
        let id = controller.id
        let name = controller.peripheral.name ?? Self.defaultDeviceName
        notificationsContinuation.yield(.connectedController(id: id, name: name))
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.disconnect()
        updateConnectionState()
        
        if central.state == .poweredOn, isPaired {
            central.scanForPeripherals(withServices: nil)
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.disconnect()
        updateConnectionState()
        
        if isPaired, deviceStore.identifiers.contains(peripheral.identifier) {
            central.connect(peripheral)
        }
    }
}
