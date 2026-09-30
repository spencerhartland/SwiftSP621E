//
//  AudioProcessor.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 9/19/26.
//

import AVFAudio
import Accelerate

enum AudioProcessorError: Error {
    case sampleCountInvalid
    case sampleCountTooLow
    case inputUnavailable
    case fftSetupInvalid
}

public actor AudioActor {
    private static let sampleBufferCount: Int = 4
    public static let bandCount = 16
    private static let bus: AVAudioNodeBus = 0
    private static let tapDuration: Double = 0.1
    
    private let engine = AVAudioEngine()
    private var audioProcessor: AudioProcessor?
    private var sessionID: UUID?
    private var processingTask: Task<Void, Never>?
    
    public init() {}
    
    public func beginSession() throws -> AsyncStream<[UInt8]> {
        endSession()
        
        let input = engine.inputNode
        let format = input.outputFormat(forBus: Self.bus)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioProcessorError.inputUnavailable
        }
        let bufferSize = AVAudioFrameCount(format.sampleRate * Self.tapDuration)
        let (signal, signalContinuation) = AsyncStream<[Float]>.makeStream(
            bufferingPolicy: .bufferingNewest(Self.sampleBufferCount)
        )
        
        Self.installTap(
            onInput: input,
            bufferSize: bufferSize,
            format: format,
            continuation: signalContinuation
        )
        
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: Self.bus)
            throw error
        }
        
        let id = UUID()
        let (frames, framesContinuation) = AsyncStream<[UInt8]>.makeStream(
            bufferingPolicy: .bufferingNewest(4)
        )
        framesContinuation.onTermination = { _ in
            Task { await self.endSession(id) }
        }
        self.audioProcessor = try AudioProcessor(
            sampleRate: format.sampleRate,
            bandCount: Self.bandCount
        )
        self.sessionID = id
        self.processingTask = Task {
            for await samples in signal {
                guard let frame = self.audioProcessor?.makeFrame(from: samples) else { break }
                framesContinuation.yield(frame)
            }
            framesContinuation.finish()
        }
        
        return frames
    }
    
    private func endSession(_ id: UUID? = nil) {
        if let id { guard id == sessionID else { return } }
        guard sessionID != nil else { return }
        processingTask?.cancel()
        processingTask = nil
        engine.stop()
        engine.inputNode.removeTap(onBus: Self.bus)
        audioProcessor = nil
        sessionID = nil
    }
    
    private static func installTap(
        onInput input: AVAudioInputNode,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat,
        continuation: AsyncStream<[Float]>.Continuation
    ) {
        if #available(iOS 27, macCatalyst 27, macOS 27, tvOS 27, visionOS 27, watchOS 27, *) {
            try? input.installAudioTap(
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

internal struct AudioProcessor {
    private static let sampleCount: Int = 4096
    private static var complexValuesCount: Int { sampleCount / 2 }
    private static let minFrequency: Float = 60
    private static let maxFrequency: Float = 16000
    private static let floor: Float = -66
    private static let ceiling: Float = -26
    private static let maxLevel: Float = 255
    private static let release: Float = 0.75
    private static let magnitudeScaleFactor: Float = 2 / Float(sampleCount)
    
    private var dft: vDSP.DiscreteFourierTransform<Float>
    private let window: [Float]
    private var bandRanges: [ClosedRange<Int>] = []
    
    private var rawSignal = [Float](repeating: 0, count: Self.sampleCount)
    private var windowedSignal = [Float](repeating: 0, count: Self.sampleCount)
    private var signalReal = [Float](repeating: 0, count: Self.complexValuesCount)
    private var signalImag = [Float](repeating: 0, count: Self.complexValuesCount)
    private var magnitudesReal = [Float](repeating: 0, count: Self.complexValuesCount)
    private var magnitudesImag = [Float](repeating: 0, count: Self.complexValuesCount)
    private var magnitudes = [Float](repeating: 0, count: Self.complexValuesCount)
    
    public var levels = [Float](repeating: 0, count: AudioActor.bandCount)
    
    public init(sampleRate: Double, bandCount: Int) throws {
        do {
            self.dft = try vDSP.DiscreteFourierTransform(
                count: Self.sampleCount,
                direction: .forward,
                transformType: .complexReal,
                ofType: Float.self
            )
        } catch {
            throw AudioProcessorError.fftSetupInvalid
        }
        self.window = vDSP.window(
            ofType: Float.self,
            usingSequence: .hanningDenormalized,
            count: Self.sampleCount,
            isHalfWindow: false
        )
        self.bandRanges = Self.makeBandRanges(sampleRate: sampleRate, bandCount: bandCount)
    }
    
    internal mutating func makeFrame(from samples: [Float]) -> [UInt8] {
        rawSignal.append(contentsOf: samples)
        rawSignal.removeFirst(rawSignal.count - Self.sampleCount)
        
        vDSP.multiply(rawSignal, window, result: &windowedSignal)
        windowedSignal.withUnsafeBufferPointer { signalPtr in
            signalReal.withUnsafeMutableBufferPointer { signalRealPtr in
                signalImag.withUnsafeMutableBufferPointer { signalImagPtr in
                    var split = DSPSplitComplex(
                        realp: signalRealPtr.baseAddress!,
                        imagp: signalImagPtr.baseAddress!
                    )
                    
                    signalPtr.withMemoryRebound(to: DSPComplex.self) { interleavedSignal in
                        vDSP_ctoz(
                            interleavedSignal.baseAddress!,
                            2,
                            &split,
                            1,
                            vDSP_Length(Self.complexValuesCount)
                        )
                    }
                }
            }
        }
        dft.transform(
            inputReal: signalReal,
            inputImaginary: signalImag,
            outputReal: &magnitudesReal,
            outputImaginary: &magnitudesImag
        )
        vDSP.hypot(magnitudesReal, magnitudesImag, result: &magnitudes)
        
        return bandRanges.indices.map { band in
            let bandRange = bandRanges[band]
            let peak = max(magnitudes[bandRange].max() ?? 0, .leastNormalMagnitude)
            let decibels = 20 * log10(peak * Self.magnitudeScaleFactor)
            let attack = (decibels - Self.floor) / (Self.ceiling - Self.floor) * Self.maxLevel
            let clamped = min(max(attack, 0), Self.maxLevel)
            let level = max(clamped, levels[band] * Self.release)
            levels[band] = level
            return UInt8(level)
        }
    }
    
    private static func makeBandRanges(sampleRate: Double, bandCount: Int) -> [ClosedRange<Int>] {
        let binWidth = Float(sampleRate) / Float(sampleCount)
        let lastBin = (sampleCount / 2) - 1
        let ratio = maxFrequency / minFrequency
        
        return (0..<bandCount).map { band in
            let lowFrequency = minFrequency * pow(ratio, Float(band) / Float(bandCount))
            let highFrequency = minFrequency * pow(ratio, Float(band + 1) / Float(bandCount))
            let lowBinIndex = Int(lowFrequency / binWidth)
            let highBinIndex = Int(highFrequency / binWidth)
            let first = min(max(1, lowBinIndex), lastBin)
            let last = min(max(first, highBinIndex), lastBin)
            return first...last
        }
    }
}
