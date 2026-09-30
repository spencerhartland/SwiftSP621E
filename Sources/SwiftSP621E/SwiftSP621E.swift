//
//  SwiftSP621E.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/29/26.
//

import Foundation
import Observation
import SwiftUI
import os

/// An object that scans for, discovers, connects to, and manages SP621E SPI LED controllers.
///
/// SwiftSP621E objects manage discovered or connected controllers (represented by SP621E objects),
/// including scanning for, discovering, and connecting to advertising controllers.
@MainActor
@Observable
public final class SwiftSP621E {
    private let group = SP621EGroup()
    private var groupNotificationsTask: Task<Void, Never>?
    
    private let audio = AudioActor()
    private var audioTask: Task<Void, Never>?
    
    private var isUpdatingState: Bool = false
    
    public let effectsStore = EffectsStore()
    /// The combined connection state of all controllers.
    public private(set) var connectionState: ConnectionState = .disconnected
    /// A boolean value indicating whether the combined connection state is `connected`.
    public var isConnected: Bool { connectionState == .connected }
    /// Discovered SP621E controllers.
    public private(set) var discoveredControllers: [DiscoveredSP621E] = []
    /// The identifiers and names of connected controllers.
    public private(set) var controllers: [UUID: String] = [:]
    /// A boolean value indicating whether pairing is complete.
    public private(set) var isPaired: Bool = false
    
    public private(set) var levels: [Float] = [Float](repeating: 0, count: AudioActor.bandCount)
    
    /// A boolean value indicating whether the connected LEDs are powered on.
    public var powerOn: Bool = false {
        didSet {
            guard !isUpdatingState else { return }
            powerOn ? group.powerOn() : group.powerOff()
        }
    }
    /// The brightness of the connected LEDs.
    public var brightness: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let value = UInt8(brightness.rounded())
            group.setBrightness(value)
        }
    }
    /// The current mode of operation.
    public var mode: SP621EMode = .solidColor {
        didSet {
            guard !isUpdatingState else { return }
            
            if mode != .audioSync { stopAudioProcessing() }
            
            switch mode {
            case .solidColor:
                effect = .none
            case .dynamicEffect:
                effect = effectsStore.recentEffect ?? .rainbow
            case .audioSync:
                effect = effectsStore.recentAudioEffect ?? .rainbow
                startAudioProcessing()
            }
        }
    }
    /// The color of the connected LEDs.
    public var color: Color = Color(red: 255, green: 0, blue: 0) {
        didSet {
            guard !isUpdatingState else { return }
            let rgb = color.rgbBytes
            let brightnessValue = UInt8(brightness.rounded())
            group.setColor(
                red: rgb.red,
                green: rgb.green,
                blue: rgb.blue,
                brightness: brightnessValue
            )
        }
    }
    /// The currently displayed dynamic lighting effect.
    public var effect: SP621EEffect = .none {
        didSet {
            guard !isUpdatingState else { return }
            group.setEffect(effect)
            switch mode {
            case .solidColor:
                return
            case .dynamicEffect:
                effectsStore.saveRecentlyUsedEffect(effect)
            case .audioSync:
                effectsStore.saveRecentlyUsedAudioEffect(effect)
            }
        }
    }
    
    /// The speed of the currently displayed dynamic lighting effect.
    public var effectSpeed: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let speed = UInt8(effectSpeed.rounded())
            group.setEffectSpeed(speed)
        }
    }
    /// The duration of one cycle of the currently displayed dynamic lighting effect.
    public var effectLength: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let length = UInt8(effectLength.rounded())
            group.setEffectLength(length)
        }
    }
    
    public var audioSensitivity: Double = 0.0 {
        didSet {
            guard !isUpdatingState else { return }
            let sensitivity = UInt8(audioSensitivity.rounded())
            group.setAudioSensitivity(sensitivity)
        }
    }
    
    /// Initializes a SwiftSP621E object.
    public init() {
        self.groupNotificationsTask = Task { [weak self] in
            guard let self else { return }
            for await notification in self.group.notifications {
                await handleGroupNotification(notification)
            }
        }
    }
    
    /// Connects to controllers.
    ///
    /// If paired controllers exist, they are connected to directly.  Otherwise, scanning begins
    /// and a list of discovered devices is published.
    public func connect() { group.connect() }
    
    /// Pairs the specified devices.
    ///
    /// - Parameter devices: The devices to pair.
    public func pairControllers(_ controllers: [DiscoveredSP621E]) {
        group.pairControllers(controllers)
    }
    
    /// Forgets all paired devices.
    public func forgetControllers() { group.forgetControllers() }
    
    public func identifyController(with id: UUID) { group.identifyController(with: id) }
    
    public func changeControllerName(id: UUID, name: String) {
        group.changeControllerName(id: id, name: name)
    }
    
    private func startAudioProcessing() {
        audioTask?.cancel()
        audioTask = Task {
            do {
                let frames = try await audio.beginSession()
                for await frame in frames {
                    levels = frame.map { Float($0) }
                    group.sendAudioFrame(frame)
                }
            } catch AudioProcessorError.sampleCountInvalid {
                Logger.audio.error("SwiftSP621E.startAudioProcessing() – Sample count invalid.")
            } catch AudioProcessorError.sampleCountTooLow {
                Logger.audio.error("SwiftSP621E.startAudioProcessing() – Sample count too low.")
            } catch AudioProcessorError.inputUnavailable {
                Logger.audio.error("SwiftSP621E.startAudioProcessing() – Input unavailable.")
            } catch AudioProcessorError.fftSetupInvalid {
                Logger.audio.error("SwiftSP621E.startAudioProcessing() – FFT setup invalid.")
            } catch {
                Logger.audio.error("SwiftSP621E.startAudioProcessing() – Unknown error.")
            }
        }
    }
    
    private func stopAudioProcessing() {
        audioTask?.cancel()
        audioTask = nil
        levels = [Float](repeating: 0, count: AudioActor.bandCount)
    }
    
    private func handleGroupNotification(_ notification: SP621EGroup.Notification) async {
        switch notification {
        case .connectionState(let connectionState):
            self.connectionState = connectionState
        case .isPaired(let pairingState):
            self.isPaired = pairingState
        case .controllerState(let state):
            self.handleControllerState(state)
        case .discoveredController(let controller):
            self.discoveredControllers.append(controller)
        case .connectedController(let id, let name):
            self.controllers[id] = name
        case .disconnectedController(let id):
            self.controllers[id] = nil
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
        self.effect = SP621EEffect(id: state.effectID)
        self.effectSpeed = Double(state.effectSpeed)
        self.effectLength = Double(state.effectLength)
        self.powerOn = state.isOn
        if mode == .audioSync { startAudioProcessing() }
        self.isUpdatingState = false
    }
}
