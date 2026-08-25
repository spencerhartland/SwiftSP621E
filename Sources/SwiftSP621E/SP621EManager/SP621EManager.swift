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
public final class SP621EManager: NSObject {
    private static let defaultDeviceName: String = "SP621E"
    
    public weak var delegate: SP621EManagerDelegate?
    
    private var central: CBCentralManager!
    
    private let deviceStore = DeviceStore()
    private var expectedControllerCount: Int { deviceStore.deviceCount }
    private var discoveredControllers: Set<UUID> = []
    private var controllers: [UUID: SP621E] = [:]
    
    private var primaryControllerID: UUID?
    public private(set) var controllerState: SP621E.State? {
        didSet { delegate?.sp621eManagerDidUpdateControllerState(self) }
    }
    
    public private(set) var isPaired: Bool = false {
        didSet { delegate?.sp621eManagerDidUpdatePairingState(self) }
    }
    
    public private(set) var connectionState: ConnectionState = .disconnected {
        didSet { delegate?.sp621eManagerDidUpdateConnectionState(self) }
    }
    
    public nonisolated override init() {
        super.init()
        Task { @BluetoothActor in
            self.central = CBCentralManager(delegate: self, queue: BluetoothActor.shared.queue)
        }
    }
    
    // MARK: Pairing and Connection -
    
    /// Connects to controllers.
    ///
    /// If paired controllers exist, the coordinator connects directly to them.  Otherwise, the
    /// coordinator begins searching and publishes a list of discovered devices
    public nonisolated func connect() {
        Task { @BluetoothActor in
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
    }
    
    /// Pairs the specified devices.
    ///
    /// - Parameter devices: The devices to pair.
    public nonisolated func pair(_ devices: [Device]) {
        Task { @BluetoothActor in
            guard !devices.isEmpty else { return }
            self.central.stopScan()
            self.deviceStore.save(devices)
            self.connectPairedDevices()
        }
    }
    
    /// Forgets all paired devices.
    public nonisolated func forgetDevices() {
        Task { @BluetoothActor in
            for controller in self.controllers.values {
                self.central.cancelPeripheralConnection(controller.peripheral)
            }
            self.controllers.removeAll()
            self.primaryControllerID = nil
            self.deviceStore.forgetDevices()
            self.searchForDevices()
        }
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
            let controller = SP621E(peripheral: peripheral)
            controller.delegate = self
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
    public nonisolated func powerOn()  {
        Task { @BluetoothActor in
            forEachController { $0.powerOn() }
        }
    }
    
    /// Power off the LEDs connected to the paired controllers.
    public nonisolated func powerOff() {
        Task { @BluetoothActor in
            forEachController { $0.powerOff() }
        }
    }
    
    /// Set the LEDs connected to the paired controllers to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the paired controllers.
    public nonisolated func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        Task { @BluetoothActor in
            forEachController {
                $0.setColor(red: red, green: green, blue: blue, brightness: brightness)
            }
        }
    }
    
    /// Set the brightness of the LEDs connected to the paired controllers.
    ///
    /// - Parameter value: The desired brightness.
    public nonisolated func setBrightness(_ value: UInt8) {
        Task { @BluetoothActor in
            forEachController { $0.setBrightness(value) }
        }
    }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    public nonisolated func setEffect(_ effect: SP621EEffect) {
        Task { @BluetoothActor in
            forEachController { $0.setEffect(effect) }
        }
    }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    public nonisolated func setEffectSpeed(_ speed: UInt8) {
        Task { @BluetoothActor in
            forEachController { $0.setEffectSpeed(speed) }
        }
    }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    public nonisolated func setEffectLength(_ length: UInt8) {
        Task { @BluetoothActor in
            forEachController { $0.setEffectLength(length) }
        }
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
        delegate?.sp621eManager(self, didRenameController: id, to: name)
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
    
    private func sync(_ controller: SP621E) async {
        let syncState: SP621E.State?
        
        if connectionState == .connected {
            syncState = await delegate?.requestedControllerState()
        } else {
            syncState = controllerState
        }
        
        guard let syncState else { return }
        controller.applyState(syncState)
    }
}

// MARK: CBCentralManagerDelegate -

extension SP621EManager: CBCentralManagerDelegate {
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
            let controller = SP621E(peripheral: peripheral)
            controller.delegate = self
            controllers[peripheral.identifier] = controller
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
            delegate?.sp621eManager(self, didDiscover: device)
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
        delegate?.sp621eManager(self, didConnectController: id, name: name)
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

// MARK: SP621EDelegate -

extension SP621EManager: SP621EDelegate {
    public func sp621eDidUpdateConnectionState(_ controller: SP621E) {
        self.updateConnectionState()
    }
    
    public func sp621eDidUpdateState(_ controller: SP621E) {
        if primaryControllerID == nil {
            primaryControllerID = controller.id
            controllerState = controller.state
        } else {
            Task { await sync(controller) }
        }
    }
}
