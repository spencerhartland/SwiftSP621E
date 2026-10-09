//
//  AudioSession.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 10/1/26.
//

import AVFAudio
import os

public actor AudioSession {
    public enum Error: Swift.Error, Equatable, Sendable {
        case activationFailed
        case inputUnavailable
        case processorSetupFailed
        case tapInstallationFailed
        case engineStartFailed
    }
    
    public enum State: Equatable, Sendable {
        case idle
        case running
        case interrupted
        case failed(AudioSession.Error)
    }
    
    /// The number of frequency bands in each frame.
    public static let bandCount = 16
    
    private static let maxResumptionWaitInSeconds: Double = 15
    private static let sampleBufferCount: Int = 4
    private static let bus: AVAudioNodeBus = 0
    private static let tapDuration: Double = 0.1
    
    public nonisolated let frames: AsyncStream<[UInt8]>
    public nonisolated let levels: AsyncStream<[Float]>
    
    private let framesContinuation: AsyncStream<[UInt8]>.Continuation
    private let levelsContinuation: AsyncStream<[Float]>.Continuation
    private let intentsContinuation: AsyncStream<Bool>.Continuation
    
    #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
    private let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    #endif
    
    private let engine = AVAudioEngine()
    private var sessionState: State = .idle
    private var audioProcessor: AudioProcessor?
    private var processingTask: Task<Void, Never>?
    private var signalContinuation: AsyncStream<[Float]>.Continuation?
    private var resumptionTask: Task<Void, Swift.Error>?
    
    public init() {
        (self.frames, self.framesContinuation) = AsyncStream.makeStream(
            bufferingPolicy: .bufferingNewest(Self.sampleBufferCount)
        )
        (self.levels, self.levelsContinuation) = AsyncStream.makeStream(
            bufferingPolicy: .bufferingNewest(Self.sampleBufferCount)
        )
        let (intents, intentsContinuation) = AsyncStream<Bool>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        self.intentsContinuation = intentsContinuation
        
        Task { [weak self] in
            for await intent in intents {
                await self?.applyIntent(intent)
            }
        }
    }
    
    deinit {
        intentsContinuation.finish()
        framesContinuation.finish()
        levelsContinuation.finish()
    }
    
    public nonisolated func setActive(_ isActive: Bool) {
        intentsContinuation.yield(isActive)
    }
    
    private func applyIntent(_ audioRequested: Bool) {
        if !audioRequested {
            resumptionTask?.cancel()
            resumptionTask = nil
        }
        
        switch (audioRequested, sessionState) {
        case (true, .running), (false, .idle):
            return
        case (true, _):
            start()
        case (false, .running):
            sessionState = .idle
            tearDown()
            deactivate()
        case (false, .interrupted), (false, .failed):
            sessionState = .idle
        }
    }
    
    private func start() {
        do throws(Error) {
            try configure()
            sessionState = .running
        } catch {
            guard sessionState != .interrupted else { return }
            sessionState = .failed(error)
        }
    }
    
    private func resume() {
        resumptionTask?.cancel()
        resumptionTask = Task {
            var delayInSeconds: Double = 0.25
            var totalWaitInSeconds: Double = 0
            while totalWaitInSeconds < Self.maxResumptionWaitInSeconds {
                guard sessionState == .interrupted else { break }
                do {
                    try configure()
                } catch {
                    totalWaitInSeconds += delayInSeconds
                    if totalWaitInSeconds < Self.maxResumptionWaitInSeconds {
                        try await Task.sleep(for: .seconds(delayInSeconds))
                        if delayInSeconds < 1 { delayInSeconds *= 2 }
                    }
                    continue
                }
                sessionState = .running
                break
            }
        }
    }
    
    private func configure() throws(AudioSession.Error) {
        #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        do {
            if audioSession.category != .record {
                try self.audioSession.setCategory(.record, mode: .measurement)
                observeAudioInterruptions()
            }
            try activate()
        } catch {
            throw .activationFailed
        }
        #endif
        
        do throws(Error) {
            try processAudio()
        } catch {
            tearDown()
            deactivate()
            throw error
        }
    }
    
    private func processAudio() throws(AudioSession.Error) {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: Self.bus)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw .inputUnavailable
        }
        
        do {
            self.audioProcessor = try AudioProcessor(
                sampleRate: format.sampleRate,
                bandCount: Self.bandCount
            )
        } catch {
            throw .processorSetupFailed
        }
        
        let (signal, signalContinuation) = AsyncStream<[Float]>.makeStream(
            bufferingPolicy: .bufferingNewest(Self.sampleBufferCount)
        )
        self.signalContinuation = signalContinuation
        self.processingTask = Task { await self.process(signal) }
        
        do {
            let bufferSize = AVAudioFrameCount(format.sampleRate * Self.tapDuration)
            try Self.installTap(
                onInput: input,
                bufferSize: bufferSize,
                format: format,
                continuation: signalContinuation
            )
        } catch {
            throw .tapInstallationFailed
        }
        
        do {
            try engine.start()
        } catch {
            throw .engineStartFailed
        }
    }
    
    private func tearDown() {
        processingTask?.cancel()
        processingTask = nil
        engine.stop()
        engine.inputNode.removeTap(onBus: Self.bus)
        signalContinuation?.finish()
        signalContinuation = nil
        audioProcessor = nil
    }
    
    private func process(_ signal: AsyncStream<[Float]>) async {
        for await samples in signal {
            guard let frame = self.audioProcessor?.makeFrame(from: samples),
                  let levels = self.audioProcessor?.levels
            else {
                return
            }
            framesContinuation.yield(frame)
            levelsContinuation.yield(levels)
        }
    }
    
    private static func installTap(
        onInput input: AVAudioInputNode,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat,
        continuation: AsyncStream<[Float]>.Continuation
    ) throws {
        if #available(iOS 27, macCatalyst 27, macOS 27, tvOS 27, visionOS 27, watchOS 27, *) {
            try input.installAudioTap(
                onBus: bus,
                bufferSize: bufferSize,
                format: format
            ) { @Sendable buffer, _ in
                guard case .float(let data) = buffer.channelData(0) else { return }
                let samples = data.withUnsafeBufferPointer { [Float]($0) }
                continuation.yield(samples)
            }
        } else {
            input.installTap(
                onBus: bus,
                bufferSize: bufferSize,
                format: format
            ) { @Sendable buffer, _ in
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameCount = Int(buffer.frameLength)
                let samples = [Float](UnsafeBufferPointer(start: channelData, count: frameCount))
                continuation.yield(samples)
            }
        }
    }
}

// MARK: AVAudioSession Lifecycle -

extension AudioSession {
    private enum InterruptionEvent {
        case began
        case ended(shouldResume: Bool)
    }
    
    private func handleInterruptionEvent(_ event: InterruptionEvent) {
        switch event {
        case .began:
            guard sessionState == .running else { return }
            sessionState = .interrupted
            tearDown()
        case .ended(let shouldResume):
            guard sessionState == .interrupted, shouldResume else { return }
            resume()
        }
    }
    
    private func activate() throws(AudioSession.Error) {
        #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        do {
            try self.audioSession.setActive(true)
        } catch {
            let reason = String(describing: error)
            Logger.audio.error("SwiftSP621E – Audio session activation error: \(reason)")
            throw .activationFailed
        }
        #endif
    }
    
    private func deactivate() {
        #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        do {
            try self.audioSession.setActive(false)
        } catch {
            Logger.audio.error("AudioSession.deactivate() – Failed to deactivate the audio session.")
        }
        #endif
    }
    
    #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
    
    private nonisolated func observeAudioInterruptions() {
        if #available(iOS 27, macCatalyst 27, tvOS 27, visionOS 27, watchOS 27, *) {
            observe(AVAudioSession.didBecomeActiveNotification) { _ in
                Logger.audio.debug("AVAudioSession.didBecomeActiveNotification")
                return nil
            }
            observe(
                AVAudioSession.didBecomeInactiveNotification,
                makeEvent: Self.deactivationEvent(from:)
            )
            observe(
                AVAudioSession.resumptionRecommendationNotification,
                makeEvent: Self.resumptionEvent(from:)
            )
        } else {
            observe(
                AVAudioSession.interruptionNotification,
                makeEvent: Self.legacyInterruptionEvent(from:)
            )
        }
    }
    
    private nonisolated func observe(
        _ name: Notification.Name,
        makeEvent: @escaping @Sendable (Notification) -> InterruptionEvent?
    ) {
        let session = audioSession
        Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: name,
                object: session
            )
            for await notification in notifications {
                guard let event = makeEvent(notification) else { continue }
                await self?.handleInterruptionEvent(event)
            }
        }
    }
    
    // MARK: Lifecycle Notifications
    
    @available(iOS 27, macCatalyst 27, tvOS 27, visionOS 27, watchOS 27, *)
    private static func deactivationEvent(from notification: Notification) -> InterruptionEvent? {
        guard let context = notification.userInfo?[AVAudioSession.deactivationContextKey]
                as? AVAudioSession.DeactivationContext
        else {
            return nil
        }
        
        switch context.source {
        case .system:
            Logger.audio.debug("AVAudioSession.didBecomeInactiveNotification - system")
            return .began
        case .app:
            Logger.audio.debug("AVAudioSession.didBecomeInactiveNotification - app")
            return nil
        @unknown default:
            return nil
        }
    }
    
    @available(iOS 27, macCatalyst 27, tvOS 27, visionOS 27, watchOS 27, *)
    private static func resumptionEvent(from notification: Notification) -> InterruptionEvent? {
        guard let context = notification.userInfo?[AVAudioSession.resumptionContextKey]
                as? AVAudioSession.ResumptionContext
                else {
            return nil
        }
        
        let shouldResume = context.recommendation == .shouldResume
        Logger.audio.debug("AVAudioSession.resumptionEvent - shouldResume: \(shouldResume)")
        return .ended(shouldResume: shouldResume)
    }
    
    // MARK: Legacy Interruption Notifications
    
    private static func legacyInterruptionEvent(
        from notification: Notification
    ) -> InterruptionEvent? {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return nil
        }
        
        switch type {
        case .began:
            Logger.audio.debug("AVAudioSession.interruptionNotification – began")
            return .began
        case .ended:
            Logger.audio.debug("AVAudioSession.interruptionNotification – ended")
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            return .ended(shouldResume: options.contains(.shouldResume))
        @unknown default:
            return nil
        }
    }
    
    #endif
}
