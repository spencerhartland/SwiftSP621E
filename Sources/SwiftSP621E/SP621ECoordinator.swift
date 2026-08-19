//
//  SP621ECoordinator.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/15/26.
//

import Foundation
import CoreBluetooth

/// Coordinates the behavior of one or more SP621E SPI LED controllers.
@BluetoothActor
public final class SP621ECoordinator: NSObject {
    public private(set) var connectionState: ConnectionState = .disconnected
    private(set) var isPaired: Bool = false
    
    private var central: CBCentralManager!
    private let deviceName = "SP621E"

    private(set) var discoveredDevices: [UUID: Device] = [:]
    
    private let deviceStore = DeviceStore()
    private(set) var controllers: [UUID: SP621E] = [:]
    private var expectedControllerCount: Int { deviceStore.deviceCount }
    
    private var primaryControllerIdentifier: UUID?
    private(set) var currentControllerState: SP621E.State?
    public var requestedControllerState: SP621E.State?
    
    public nonisolated override init() {
        super.init()
    }
    
    // MARK: Pairing and Connection -
    
    /// Connects to controllers.
    ///
    /// If paired controllers exist, the coordinator connects directly to them.  Otherwise, the
    /// coordinator begins searching and publishes a list of discovered devices.
    public func connect() {
        startCentralManager()
        guard self.central.state == .poweredOn else { return }
        
        if self.deviceStore.isEmpty {
            self.searchForDevices()
        } else {
            self.connectPairedDevices()
        }
    }
    
    /// Pairs the specified devices.
    ///
    /// - Parameter devices: The devices to pair.
    public func pair(_ devices: [Device]) {
        guard !devices.isEmpty else { return }
        self.central.stopScan()
        self.deviceStore.save(devices)
        self.discoveredDevices.removeAll()
        self.connectPairedDevices()
    }
    
    /// Forgets all paired devices.
    public func forgetDevices() {
        for controller in self.controllers.values {
            self.central.cancelPeripheralConnection(controller.peripheral)
        }
        self.controllers.removeAll()
        self.primaryControllerIdentifier = nil
        self.currentControllerState = nil
        self.deviceStore.forgetDevices()
        self.searchForDevices()
    }
    
    private func startCentralManager() {
        guard central == nil else { return }
        central = CBCentralManager(delegate: self, queue: BluetoothActor.shared.queue)
    }

    private func searchForDevices() {
        isPaired = false
        connectionState = .connecting
        discoveredDevices.removeAll()
        central.scanForPeripherals(withServices: nil)
    }
    
    private func connectPairedDevices() {
        isPaired = true
        connectionState = .connecting
        
        let knownDevices = central.retrievePeripherals(withIdentifiers: deviceStore.identifiers)
        for peripheral in knownDevices {
            guard controllers[peripheral.identifier] == nil else { continue }
            let controller = SP621E(peripheral: peripheral, queue: BluetoothActor.shared.queue)
            subscribeToUpdates(from: controller)
            controllers[peripheral.identifier] = controller
            central.connect(peripheral)
        }
        
        let missingDevices = Set(deviceStore.identifiers).subtracting(controllers.keys)
        if !missingDevices.isEmpty {
            central.scanForPeripherals(withServices: nil)
        }
    }
    
    // MARK: SP621E Commands -
    
    /// Power on the LEDs connected to the paired controllers.
    public func powerOn()  { forEachController { $0.powerOn() } }
    
    /// Power off the LEDs connected to the paired controllers.
    public func powerOff() { forEachController { $0.powerOff() } }
    
    /// Set the LEDs connected to the paired controllers to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the paired controllers.
    public func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        forEachController { $0.setColor(red: red, green: green, blue: blue, brightness: brightness) }
    }
    
    /// Set the brightness of the LEDs connected to the paired controllers.
    ///
    /// - Parameter value: The desired brightness.
    public func setBrightness(_ value: UInt8) { forEachController { $0.setBrightness(value) } }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    public func setEffect(_ effect: SP621E.Effect) { forEachController { $0.setEffect(effect) } }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    public func setEffectSpeed(_ speed: UInt8) { forEachController { $0.setEffectSpeed(speed) } }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    public func setEffectLength(_ length: UInt8) { forEachController { $0.setEffectLength(length) } }
    
    /// Change the name of the controller with the specified identifier.
    ///
    /// - Parameters:
    ///     - id: The identifier of the controller to rename.
    ///     - name: The new name of the controller.
    public func renameController(with id: UUID, to name: String) {
        guard let controller = controllers[id] else { return } // TODO: Throw error
        controller.rename(to: name)
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
            connectionState = .connected
        } else if connectedCount == 0 {
            connectionState = .disconnected
        } else {
            connectionState = .connecting
        }
        
        if controllers.values.allSatisfy({ $0.connectionState != .connected }) {
            primaryControllerIdentifier = nil
            currentControllerState = nil
        }
    }

    private func subscribeToUpdates(from controller: SP621E) {
        controller.onConnectionStateChange = { [weak self] _ in self?.updateConnectionState() }
        
        controller.onStateNotification = { [weak self] deviceState in
            self?.handleStateNotification(from: controller, deviceState)
        }
    }

    private func handleStateNotification(from controller: SP621E, _ controllerState: SP621E.State) {
        // First controller to report state becomes primary.
        if primaryControllerIdentifier == nil {
            primaryControllerIdentifier = controller.identifier
            self.currentControllerState = controllerState
        } else {
            sync(controller)
        }
    }
    
    private func sync(_ controller: SP621E) {
        let syncState: SP621E.State?
        
        if connectionState == .connected {
            syncState = requestedControllerState
        } else {
            syncState = currentControllerState
        }
        
        guard let syncState else { return }
        controller.applyState(syncState)
    }
}

// MARK: CBCentralManagerDelegate -

extension SP621ECoordinator: CBCentralManagerDelegate {
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
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? ""
        guard name.contains(deviceName) else { return }
        
        if isPaired {
            guard deviceStore.identifiers.contains(peripheral.identifier),
                  controllers[peripheral.identifier] == nil else {
                return
            }
            let controller = SP621E(peripheral: peripheral, queue: BluetoothActor.shared.queue)
            subscribeToUpdates(from: controller)
            controllers[peripheral.identifier] = controller
            central.connect(peripheral)
            
            let allDevicesConnected = Set(deviceStore.identifiers).isSubset(of: controllers.keys)
            if allDevicesConnected { central.stopScan() }
        } else {
            discoveredDevices[peripheral.identifier] = Device(
                id: peripheral.identifier,
                name: advName ?? peripheral.name ?? deviceName,
                rssi: RSSI.intValue
            )
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        controllers[peripheral.identifier]?.connect()
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
