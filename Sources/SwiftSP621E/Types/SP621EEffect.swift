//
//  SP621EEffect.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

public struct SP621EEffect: Identifiable, Sendable, Equatable, Hashable, Codable {
    public enum EffectType: Sendable, Codable {
        case standard
        case audio
    }
    
    public let type: EffectType
    public let id: UInt8
    public let name: String
    
    init(id: UInt8, type: EffectType = .standard) {
        self = Self.allEffects[id] ?? .init(name: "Effect \(id)", id: id, type: type)
    }
    
    init(name: String, id: UInt8, type: EffectType) {
        self.name = name
        self.id = id
        self.type = type
    }
}

extension SP621EEffect {
    // None: turns off effects
    public static let none = SP621EEffect(name: "None", id: 0xBE, type: .standard)
    
    // Dynamic Effects: looping animations (0x01 - 0x8E)
    public static let rainbow = SP621EEffect(name: "Rainbow", id: 0x01, type: .standard)
    public static let rainbow2 = SP621EEffect(name: "Rainbow 2", id: 0x02, type: .standard)
    
    // Audio Effects: react to microphone audio
    public static let fullColorRhythmSpectrum = SP621EEffect(
        name: "Rhythm Spectrum (Multicolor)",
        id: 0xC9,
        type: .audio
    )
    public static let singleColorRhythmSpectrum = SP621EEffect(
        name: "Rhythm Spectrum (Single Color)",
        id: 0xCA,
        type: .audio
    )
    public static let fullColorRhythmStars = SP621EEffect(
        name: "Rhythm Stars (Multicolor)",
        id: 0xCB,
        type: .audio
    )
    public static let singleColorRhythmStars = SP621EEffect(
        name: "Rhythm Stars (Single Color)",
        id: 0xCC,
        type: .audio
    )
    public static let gradientEnergy = SP621EEffect(
        name: "Energy (Multicolor)",
        id: 0xCD,
        type: .audio
    )
    public static let singleColorEnergy = SP621EEffect(
        name: "Energy (Single Color)",
        id: 0xCE,
        type: .audio
    )
    public static let gradientPulse = SP621EEffect(
        name: "Pulse (Multicolor)",
        id: 0xCF,
        type: .audio
    )
    public static let singleColorPulse = SP621EEffect(
        name: "Pulse (Single Color)",
        id: 0xD0,
        type: .audio
    )
    public static let fullColorEjectionForward = SP621EEffect(
        name: "Ejection Forward (Multicolor)",
        id: 0xD1,
        type: .audio
    )
    public static let singleColorEjectionForward = SP621EEffect(
        name: "Ejection Forward (Single Color)",
        id: 0xD2,
        type: .audio
    )
    public static let fullColorEjectionBackward = SP621EEffect(
        name: "Ejection Backward (Multicolor)",
        id: 0xD3,
        type: .audio
    )
    public static let singleColorEjectionBackward = SP621EEffect(
        name: "Ejection Backward (Single Color)",
        id: 0xD4,
        type: .audio
    )
    public static let fullColorVUMeter = SP621EEffect(
        name: "VU Meter (Multicolor)",
        id: 0xD5,
        type: .audio
    )
    public static let singleColorVUMeter = SP621EEffect(
        name: "VU Meter (Single Color)",
        id: 0xD6,
        type: .audio
    )
    public static let loveAndPeace = SP621EEffect(
        name: "Love&Peace",
        id: 0xD7,
        type: .audio
    )
    public static let festive = SP621EEffect(
        name: "Festive",
        id: 0xD8,
        type: .audio
    )
    public static let heatBeat = SP621EEffect(
        name: "HeatBeat",
        id: 0xD9,
        type: .audio
    )
    public static let party = SP621EEffect(
        name: "Party",
        id: 0xDA,
        type: .audio
    )
}

extension SP621EEffect {
    public static let effects: [SP621EEffect] = [
        rainbow,
        rainbow2,
        fullColorRhythmSpectrum,
        singleColorRhythmSpectrum,
        fullColorRhythmStars,
        singleColorRhythmStars,
        gradientEnergy,
        singleColorEnergy,
        gradientPulse,
        singleColorPulse,
        fullColorEjectionForward,
        singleColorEjectionForward,
        fullColorEjectionBackward,
        singleColorEjectionBackward,
        fullColorVUMeter,
        singleColorVUMeter,
        loveAndPeace,
        festive,
        heatBeat,
        party
    ]
    
    private static let combined: [SP621EEffect] = effects + [.none]
    private static let allEffects: [UInt8: SP621EEffect] = Dictionary(
        uniqueKeysWithValues: combined.map { ($0.id, $0) }
    )
}
