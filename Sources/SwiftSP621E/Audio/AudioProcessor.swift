//
//  AudioProcessor.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 9/19/26.
//

import Accelerate

internal struct AudioProcessor {
    enum Error: Swift.Error {
        case fftSetupInvalid
    }
    
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
    
    public var levels = [Float](repeating: 0, count: AudioSession.bandCount)
    
    public init(sampleRate: Double, bandCount: Int) throws(AudioProcessor.Error) {
        do {
            self.dft = try vDSP.DiscreteFourierTransform(
                count: Self.sampleCount,
                direction: .forward,
                transformType: .complexReal,
                ofType: Float.self
            )
        } catch {
            throw .fftSetupInvalid
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
