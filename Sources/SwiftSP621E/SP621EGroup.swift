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
        case discoveredController(DiscoveredSP621E)
        case connectedController(id: UUID, name: String)
        case disconnectedController(id: UUID)
        case renamedController(id: UUID, name: String)
    }
    
    private enum Command: Sendable {
        case connect
        case forget
        case pairControllers([DiscoveredSP621E])
        case powerOn(Bool)
        case setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8)
        case setBrightness(UInt8)
        case setEffect(SP621EEffect)
        case setEffectSpeed(UInt8)
        case setEffectLength(UInt8)
        case identifyController(UUID)
        case changeControllerName(UUID, String)
    }
    
    private var central: CBCentralManager!
    
    private let sp621eStore = SP621EStore()
    private var expectedControllerCount: Int { sp621eStore.deviceCount }
    private var discoveredControllers: Set<UUID> = []
    private var controllers: [UUID: SP621E] = [:]
    
    public let notifications: AsyncStream<Notification>
    private let notificationsContinuation: AsyncStream<Notification>.Continuation
    
    private let controllerNotifications: AsyncStream<SP621E.Notification>
    private let controllerNotificationsContinuation: AsyncStream<SP621E.Notification>.Continuation
    
    private let commands: AsyncThrottleSequence<AsyncStream<Command>, ContinuousClock, Command>
    private let commandsContinuation: AsyncStream<Command>.Continuation
    
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
    
    private func searchForDevices() {
        self.isPaired = false
        self.connectionState = .connecting
        self.discoveredControllers.removeAll()
        central.scanForPeripherals(withServices: [Bluetooth.advertisedServiceUUID])
    }
    
    private func connectPairedControllers() {
        self.isPaired = true
        self.connectionState = .connecting
        
        let knownDevices = central.retrievePeripherals(withIdentifiers: sp621eStore.identifiers)
        for peripheral in knownDevices {
            guard controllers[peripheral.identifier] == nil else { continue }
            handleConnectedController(peripheral)
            central.connect(peripheral)
        }
        
        let missingDevices = Set(sp621eStore.identifiers).subtracting(controllers.keys)
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
    
    private func handleDisconnectedController(with id: UUID) {
        controllers[id] = nil
        notificationsContinuation.yield(.disconnectedController(id: id))
    }
    
    private func handleControllerNotification(_ notification: SP621E.Notification) {
        switch notification {
        case .connectionState(let id, let state):
            self.updateConnectionState()
            if state == .disconnected { handleDisconnectedController(with: id) }
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

// MARK: Public Methods -

extension SP621EGroup {
    /// Connects to controllers.
    public nonisolated func connect() { commandsContinuation.yield(.connect) }
    
    /// Pairs the specified controllers.
    ///
    /// - Parameter controllers: The controllers to pair.
    public nonisolated func pairControllers(_ controllers: [DiscoveredSP621E]) {
        commandsContinuation.yield(.pairControllers(controllers))
    }
    
    /// Forgets all paired controllers.
    public nonisolated func forgetControllers() { commandsContinuation.yield(.forget) }
    
    /// Power on the LEDs connected to the paired controllers.
    public nonisolated func powerOn()  { commandsContinuation.yield(.powerOn(true)) }
    
    /// Power off the LEDs connected to the paired controllers.
    public nonisolated func powerOff() { commandsContinuation.yield(.powerOn(false)) }
    
    /// Set the LEDs connected to the paired controllers to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the paired controllers.
    public nonisolated func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        commandsContinuation.yield(
            .setColor(red: red, green: green, blue: blue, brightness: brightness)
        )
    }
    
    /// Set the brightness of the LEDs connected to the paired controllers.
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
    
    public nonisolated func identifyController(with id: UUID) {
        commandsContinuation.yield(.identifyController(id))
    }
    
    public nonisolated func changeControllerName(id: UUID, name: String) {
        commandsContinuation.yield(.changeControllerName(id, name))
    }
}

// MARK: Command Handling -

extension SP621EGroup {
    private func forEachController(_ action: (SP621E) -> Void) {
        for controller in controllers.values {
            action(controller)
        }
    }
    
    private func handleCommand(_ command: Command) {
        switch command {
        case .connect:
            handleConnect()
        case .forget:
            handleForget()
        case .pairControllers(let controllers):
            handlePairingControllers(controllers)
        case .powerOn(let isOn):
            handlePowerOn(isOn)
        case .setColor(let red, let green, let blue, let brightness):
            handleSetColor(red: red, green: green, blue: blue, brightness: brightness)
        case .setBrightness(let value):
            handleSetBrightness(value)
        case .setEffect(let effect):
            handleSetEffect(effect)
        case .setEffectSpeed(let speed):
            handleSetEffectSpeed(speed)
        case .setEffectLength(let length):
            handleSetEffectLength(length)
        case .identifyController(let id):
            handleIdentifyController(with: id)
        case .changeControllerName(let id, let name):
            handleNameChange(for: id, name: name)
        }
    }
    
    private func handleConnect() {
        guard self.central.state == .poweredOn,
              self.connectionState == .disconnected
        else {
            return
        }
        
        if self.sp621eStore.isEmpty {
            Logger.bluetooth.info("Searching for devices...")
            self.searchForDevices()
        } else {
            Logger.bluetooth.info("Connecting paired devices...")
            self.connectPairedControllers()
        }
    }
    
    private func handleForget() {
        for controller in self.controllers.values {
            self.central.cancelPeripheralConnection(controller.peripheral)
        }
        self.controllers.removeAll()
        self.primaryControllerID = nil
        self.sp621eStore.forgetControllers()
        self.searchForDevices()
    }
    
    private func handlePairingControllers(_ controllers: [DiscoveredSP621E]) {
        guard !controllers.isEmpty else { return }
        self.central.stopScan()
        self.sp621eStore.saveControllers(controllers)
        self.connectPairedControllers()
    }
    
    private func handlePowerOn(_ isOn: Bool) {
        if isOn {
            forEachController { $0.powerOn() }
        } else {
            forEachController { $0.powerOff() }
        }
    }
    
    private func handleSetColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        forEachController {
            $0.setColor(red: red, green: green, blue: blue, brightness: brightness)
        }
    }
    
    private func handleSetBrightness(_ value: UInt8) {
        forEachController { $0.setBrightness(value) }
    }
    
    private func handleSetEffect(_ effect: SP621EEffect) {
        forEachController { $0.setEffect(effect) }
    }
    
    private func handleSetEffectSpeed(_ speed: UInt8) {
        forEachController { $0.setEffectSpeed(speed) }
    }
    
    private func handleSetEffectLength(_ length: UInt8) {
        forEachController { $0.setEffectLength(length) }
    }
    
    private func handleIdentifyController(with id: UUID) {
        guard let controller = controllers[id] else { return }
        controller.identify()
    }
    
    private func handleNameChange(for id: UUID, name: String) {
        guard let controller = controllers[id] else { return }
        try? controller.changeName(to: name)
        notificationsContinuation.yield(.renamedController(id: id, name: name))
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
        Logger.bluetooth.info("centralManager didDiscover called.")
        let mfgPrefixLength = Bluetooth.manufacturerPrefix.count
        
        guard let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              mfgData.count >= mfgPrefixLength,
              mfgData.prefix(mfgPrefixLength).elementsEqual(Bluetooth.manufacturerPrefix)
        else {
            Logger.bluetooth.error("mfg data does not match!")
            return
        }
        
        if isPaired {
            guard sp621eStore.identifiers.contains(peripheral.identifier),
                  controllers[peripheral.identifier] == nil else {
                return
            }
            handleConnectedController(peripheral)
            central.connect(peripheral)
            
            let allDevicesConnected = Set(sp621eStore.identifiers).isSubset(of: controllers.keys)
            if allDevicesConnected { central.stopScan() }
        } else {
            guard !discoveredControllers.contains(peripheral.identifier) else { return }
            discoveredControllers.insert(peripheral.identifier)
            
            let controller = DiscoveredSP621E(
                id: peripheral.identifier,
                name: peripheral.name ?? SP621E.defaultName,
                rssi: RSSI.intValue
            )
            Logger.bluetooth.info("centralManager didDiscover yielding discovered controller...")
            notificationsContinuation.yield(.discoveredController(controller))
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        if controllers[peripheral.identifier] == nil {
            handleConnectedController(peripheral)
        }
        
        guard let controller = controllers[peripheral.identifier] else { return }
        controller.connect()
        
        notificationsContinuation.yield(
            .connectedController(id: controller.id, name: controller.name)
        )
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
        
        if isPaired, sp621eStore.identifiers.contains(peripheral.identifier) {
            central.connect(peripheral)
        }
    }
}
