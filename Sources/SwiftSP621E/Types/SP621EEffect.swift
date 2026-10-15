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
    public static let rainbow = SP621EEffect(
        name: "Rainbow",
        id: 0x01,
        type: .standard
    )
    public static let rainbowMeteor = SP621EEffect(
        name: "Rainbow Meteor",
        id: 0x02,
        type: .standard
    )
    public static let rainbowStars = SP621EEffect(
        name: "Rainbow Stars",
        id: 0x03,
        type: .standard
    )
    public static let rainbowSpin = SP621EEffect(
        name: "Rainbow Spin",
        id: 0x04,
        type: .standard
    )
    public static let redYellowFire = SP621EEffect(
        name: "Red-Yellow Fire",
        id: 0x05,
        type: .standard
    )
    public static let redPurpleFire = SP621EEffect(
        name: "Red-Purple Fire",
        id: 0x06,
        type: .standard
    )
    public static let greenYellowFire = SP621EEffect(
        name: "Green-Yellow Fire",
        id: 0x07,
        type: .standard
    )
    public static let greenCyanFire = SP621EEffect(
        name: "Green-Cyan Fire",
        id: 0x08,
        type: .standard
    )
    public static let bluePurpleFire = SP621EEffect(
        name: "Blue-Purple Fire",
        id: 0x09,
        type: .standard
    )
    public static let blueCyanFire = SP621EEffect(
        name: "Blue-Cyan Fire",
        id: 0x0A,
        type: .standard
    )
    public static let redComet = SP621EEffect(
        name: "Red Comet",
        id: 0x0B,
        type: .standard
    )
    public static let greenComet = SP621EEffect(
        name: "Green Comet",
        id: 0x0C,
        type: .standard
    )
    public static let blueComet = SP621EEffect(
        name: "Blue Comet",
        id: 0x0D,
        type: .standard
    )
    public static let yellowComet = SP621EEffect(
        name: "Yellow Comet",
        id: 0x0E,
        type: .standard
    )
    public static let cyanComet = SP621EEffect(
        name: "Cyan Comet",
        id: 0x0F,
        type: .standard
    )
    public static let purpleComet = SP621EEffect(
        name: "Purple Comet",
        id: 0x10,
        type: .standard
    )
    public static let whiteComet = SP621EEffect(
        name: "White Comet",
        id: 0x11,
        type: .standard
    )
    public static let redMeteor = SP621EEffect(
        name: "Red Meteor",
        id: 0x12,
        type: .standard
    )
    public static let greenMeteor = SP621EEffect(
        name: "Green Meteor",
        id: 0x13,
        type: .standard
    )
    public static let blueMeteor = SP621EEffect(
        name: "Blue Meteor",
        id: 0x14,
        type: .standard
    )
    public static let yellowMeteor = SP621EEffect(
        name: "Yellow Meteor",
        id: 0x15,
        type: .standard
    )
    public static let cyanMeteor = SP621EEffect(
        name: "Cyan Meteor",
        id: 0x16,
        type: .standard
    )
    public static let purpleMeteor = SP621EEffect(
        name: "Purple Meteor",
        id: 0x17,
        type: .standard
    )
    public static let whiteMeteor = SP621EEffect(
        name: "White Meteor",
        id: 0x18,
        type: .standard
    )
    public static let redGreenGradientSnake = SP621EEffect(
        name: "Red-Green Gradient Snake",
        id: 0x19,
        type: .standard
    )
    public static let redBlueGradientSnake = SP621EEffect(
        name: "Red-Blue Gradient Snake",
        id: 0x1A,
        type: .standard
    )
    public static let redYellowGradientSnake = SP621EEffect(
        name: "Red-Yellow Gradient Snake",
        id: 0x1B,
        type: .standard
    )
    public static let redCyanGradientSnake = SP621EEffect(
        name: "Red-Cyan Gradient Snake",
        id: 0x1C,
        type: .standard
    )
    public static let redPurpleGradientSnake = SP621EEffect(
        name: "Red-Purple Gradient Snake",
        id: 0x1D,
        type: .standard
    )
    public static let redWhiteGradientSnake = SP621EEffect(
        name: "Red-White Gradient Snake",
        id: 0x1E,
        type: .standard
    )
    public static let greenBlueGradientSnake = SP621EEffect(
        name: "Green-Blue Gradient Snake",
        id: 0x1F,
        type: .standard
    )
    public static let greenYellowGradientSnake = SP621EEffect(
        name: "Green-Yellow Gradient Snake",
        id: 0x20,
        type: .standard
    )
    public static let greenCyanGradientSnake = SP621EEffect(
        name: "Green-Cyan Gradient Snake",
        id: 0x21,
        type: .standard
    )
    public static let greenPurpleGradientSnake = SP621EEffect(
        name: "Green-Purple Gradient Snake",
        id: 0x22,
        type: .standard
    )
    public static let greenWhiteGradientSnake = SP621EEffect(
        name: "Green-White Gradient Snake",
        id: 0x23,
        type: .standard
    )
    public static let blueYellowGradientSnake = SP621EEffect(
        name: "Blue-Yellow Gradient Snake",
        id: 0x24,
        type: .standard
    )
    public static let blueCyanGradientSnake = SP621EEffect(
        name: "Blue-Cyan Gradient Snake",
        id: 0x25,
        type: .standard
    )
    public static let bluePurpleGradientSnake = SP621EEffect(
        name: "Blue-Purple Gradient Snake",
        id: 0x26,
        type: .standard
    )
    public static let blueWhiteGradientSnake = SP621EEffect(
        name: "Blue-White Gradient Snake",
        id: 0x27,
        type: .standard
    )
    public static let yellowCyanGradientSnake = SP621EEffect(
        name: "Yellow-Cyan Gradient Snake",
        id: 0x28,
        type: .standard
    )
    public static let yellowPurpleGradientSnake = SP621EEffect(
        name: "Yellow-Purple Gradient Snake",
        id: 0x29,
        type: .standard
    )
    public static let yellowWhiteGradientSnake = SP621EEffect(
        name: "Yellow-White Gradient Snake",
        id: 0x2A,
        type: .standard
    )
    public static let cyanPurpleGradientSnake = SP621EEffect(
        name: "Cyan-Purple Gradient Snake",
        id: 0x2B,
        type: .standard
    )
    public static let cyanWhiteGradientSnake = SP621EEffect(
        name: "Cyan-White Gradient Snake",
        id: 0x2C,
        type: .standard
    )
    public static let purpleWhiteGradientSnake = SP621EEffect(
        name: "Purple-White Gradient Snake",
        id: 0x2D,
        type: .standard
    )
    public static let redWave = SP621EEffect(
        name: "Red Wave",
        id: 0x2E,
        type: .standard
    )
    public static let greenWave = SP621EEffect(
        name: "Green Wave",
        id: 0x2F,
        type: .standard
    )
    public static let blueWave = SP621EEffect(
        name: "Blue Wave",
        id: 0x30,
        type: .standard
    )
    public static let yellowWave = SP621EEffect(
        name: "Yellow Wave",
        id: 0x31,
        type: .standard
    )
    public static let cyanWave = SP621EEffect(
        name: "Cyan Wave",
        id: 0x32,
        type: .standard
    )
    public static let purpleWave = SP621EEffect(
        name: "Purple Wave",
        id: 0x33,
        type: .standard
    )
    public static let whiteWave = SP621EEffect(
        name: "White Wave",
        id: 0x34,
        type: .standard
    )
    public static let redGreenWave = SP621EEffect(
        name: "Red-Green Wave",
        id: 0x35,
        type: .standard
    )
    public static let redBlueWave = SP621EEffect(
        name: "Red-Blue Wave",
        id: 0x36,
        type: .standard
    )
    public static let redYellowWave = SP621EEffect(
        name: "Red-Yellow Wave",
        id: 0x37,
        type: .standard
    )
    public static let redCyanWave = SP621EEffect(
        name: "Red-Cyan Wave",
        id: 0x38,
        type: .standard
    )
    public static let redPurpleWave = SP621EEffect(
        name: "Red-Purple Wave",
        id: 0x39,
        type: .standard
    )
    public static let redWhiteWave = SP621EEffect(
        name: "Red-White Wave",
        id: 0x3A,
        type: .standard
    )
    public static let greenBlueWave = SP621EEffect(
        name: "Green-Blue Wave",
        id: 0x3B,
        type: .standard
    )
    public static let greenYellowWave = SP621EEffect(
        name: "Green-Yellow Wave",
        id: 0x3C,
        type: .standard
    )
    public static let greenCyanWave = SP621EEffect(
        name: "Green-Cyan Wave",
        id: 0x3D,
        type: .standard
    )
    public static let greenPurpleWave = SP621EEffect(
        name: "Green-Purple Wave",
        id: 0x3E,
        type: .standard
    )
    public static let greenWhiteWave = SP621EEffect(
        name: "Green-White Wave",
        id: 0x3F,
        type: .standard
    )
    public static let blueYellowWave = SP621EEffect(
        name: "Blue-Yellow Wave",
        id: 0x40,
        type: .standard
    )
    public static let blueCyanWave = SP621EEffect(
        name: "Blue-Cyan Wave",
        id: 0x41,
        type: .standard
    )
    public static let bluePurpleWave = SP621EEffect(
        name: "Blue-Purple Wave",
        id: 0x42,
        type: .standard
    )
    public static let blueWhiteWave = SP621EEffect(
        name: "Blue-White Wave",
        id: 0x43,
        type: .standard
    )
    public static let yellowCyanWave = SP621EEffect(
        name: "Yellow-Cyan Wave",
        id: 0x44,
        type: .standard
    )
    public static let yellowPurpleWave = SP621EEffect(
        name: "Yellow-Purple Wave",
        id: 0x45,
        type: .standard
    )
    public static let yellowWhiteWave = SP621EEffect(
        name: "Yellow-White Wave",
        id: 0x46,
        type: .standard
    )
    public static let cyanPurpleWave = SP621EEffect(
        name: "Cyan-Purple Wave",
        id: 0x47,
        type: .standard
    )
    public static let cyanWhiteWave = SP621EEffect(
        name: "Cyan-White Wave",
        id: 0x48,
        type: .standard
    )
    public static let purpleWhiteWave = SP621EEffect(
        name: "Purple-White Wave",
        id: 0x49,
        type: .standard
    )
    public static let redStars = SP621EEffect(
        name: "Red Stars",
        id: 0x4A,
        type: .standard
    )
    public static let greenStars = SP621EEffect(
        name: "Green Stars",
        id: 0x4B,
        type: .standard
    )
    public static let blueStars = SP621EEffect(
        name: "Blue Stars",
        id: 0x4C,
        type: .standard
    )
    public static let yellowStars = SP621EEffect(
        name: "Yellow Stars",
        id: 0x4D,
        type: .standard
    )
    public static let cyanStars = SP621EEffect(
        name: "Cyan Stars",
        id: 0x4E,
        type: .standard
    )
    public static let purpleStars = SP621EEffect(
        name: "Purple Stars",
        id: 0x4F,
        type: .standard
    )
    public static let whiteStars = SP621EEffect(
        name: "White Stars",
        id: 0x50,
        type: .standard
    )
    public static let redTwinklingStars = SP621EEffect(
        name: "Red Twinkling Stars",
        id: 0x51,
        type: .standard
    )
    public static let greenTwinklingStars = SP621EEffect(
        name: "Green Twinkling Stars",
        id: 0x52,
        type: .standard
    )
    public static let blueTwinklingStars = SP621EEffect(
        name: "Blue Twinkling Stars",
        id: 0x53,
        type: .standard
    )
    public static let yellowTwinklingStars = SP621EEffect(
        name: "Yellow Twinkling Stars",
        id: 0x54,
        type: .standard
    )
    public static let cyanTwinklingStars = SP621EEffect(
        name: "Cyan Twinkling Stars",
        id: 0x55,
        type: .standard
    )
    public static let purpleTwinklingStars = SP621EEffect(
        name: "Purple Twinkling Stars",
        id: 0x56,
        type: .standard
    )
    public static let redWhiteTwinklingStars = SP621EEffect(
        name: "Red-White Twinkling Stars",
        id: 0x57,
        type: .standard
    )
    public static let greenWhiteTwinklingStars = SP621EEffect(
        name: "Green-White Twinkling Stars",
        id: 0x58,
        type: .standard
    )
    public static let blueWhiteTwinklingStars = SP621EEffect(
        name: "Blue-White Twinkling Stars",
        id: 0x59,
        type: .standard
    )
    public static let yellowWhiteTwinklingStars = SP621EEffect(
        name: "Yellow-White Twinkling Stars",
        id: 0x5A,
        type: .standard
    )
    public static let cyanWhiteTwinklingStars = SP621EEffect(
        name: "Cyan-White Twinkling Stars",
        id: 0x5B,
        type: .standard
    )
    public static let purpleWhiteTwinklingStars = SP621EEffect(
        name: "Purple-White Twinkling Stars",
        id: 0x5C,
        type: .standard
    )
    public static let whiteTwinklingStars = SP621EEffect(
        name: "White Twinkling Stars",
        id: 0x5D,
        type: .standard
    )
    public static let redBreath = SP621EEffect(
        name: "Red Breath",
        id: 0x5E,
        type: .standard
    )
    public static let greenBreath = SP621EEffect(
        name: "Green Breath",
        id: 0x5F,
        type: .standard
    )
    public static let blueBreath = SP621EEffect(
        name: "Blue Breath",
        id: 0x60,
        type: .standard
    )
    public static let yellowBreath = SP621EEffect(
        name: "Yellow Breath",
        id: 0x61,
        type: .standard
    )
    public static let cyanBreath = SP621EEffect(
        name: "Cyan Breath",
        id: 0x62,
        type: .standard
    )
    public static let purpleBreath = SP621EEffect(
        name: "Purple Breath",
        id: 0x63,
        type: .standard
    )
    public static let whiteBreath = SP621EEffect(
        name: "White Breath",
        id: 0x64,
        type: .standard
    )
    public static let redStack = SP621EEffect(
        name: "Red Stack",
        id: 0x65,
        type: .standard
    )
    public static let greenStack = SP621EEffect(
        name: "Green Stack",
        id: 0x66,
        type: .standard
    )
    public static let blueStack = SP621EEffect(
        name: "Blue Stack",
        id: 0x67,
        type: .standard
    )
    public static let yellowStack = SP621EEffect(
        name: "Yellow Stack",
        id: 0x68,
        type: .standard
    )
    public static let cyanStack = SP621EEffect(
        name: "Cyan Stack",
        id: 0x69,
        type: .standard
    )
    public static let purpleStack = SP621EEffect(
        name: "Purple Stack",
        id: 0x6A,
        type: .standard
    )
    public static let whiteStack = SP621EEffect(
        name: "White Stack",
        id: 0x6B,
        type: .standard
    )
    public static let fullColorStack = SP621EEffect(
        name: "Full Color Stack",
        id: 0x6C,
        type: .standard
    )
    public static let redGreenStack = SP621EEffect(
        name: "Red-Green Stack",
        id: 0x6D,
        type: .standard
    )
    public static let greenBlueStack = SP621EEffect(
        name: "Green-Blue Stack",
        id: 0x6E,
        type: .standard
    )
    public static let blueYellowStack = SP621EEffect(
        name: "Blue-Yellow Stack",
        id: 0x6F,
        type: .standard
    )
    public static let yellowCyanStack = SP621EEffect(
        name: "Yellow-Cyan Stack",
        id: 0x70,
        type: .standard
    )
    public static let cyanPurpleStack = SP621EEffect(
        name: "Cyan-Purple Stack",
        id: 0x71,
        type: .standard
    )
    public static let purpleWhiteStack = SP621EEffect(
        name: "Purple-White Stack",
        id: 0x72,
        type: .standard
    )
    public static let redWhiteBlueSnake = SP621EEffect(
        name: "Red-White-Blue Snake",
        id: 0x73,
        type: .standard
    )
    public static let greenWhiteYellowSnake = SP621EEffect(
        name: "Green-White-Yellow Snake",
        id: 0x74,
        type: .standard
    )
    public static let redGreenWhiteSnake = SP621EEffect(
        name: "Red-Green-White Snake",
        id: 0x75,
        type: .standard
    )
    public static let redYellowSnake = SP621EEffect(
        name: "Red-Yellow Snake",
        id: 0x76,
        type: .standard
    )
    public static let redWhiteSnake = SP621EEffect(
        name: "Red-White Snake",
        id: 0x77,
        type: .standard
    )
    public static let greenWhiteSnake = SP621EEffect(
        name: "Green-White Snake",
        id: 0x78,
        type: .standard
    )
    public static let redCometSpin = SP621EEffect(
        name: "Red Comet Spin",
        id: 0x79,
        type: .standard
    )
    public static let greenCometSpin = SP621EEffect(
        name: "Green Comet Spin",
        id: 0x7A,
        type: .standard
    )
    public static let blueCometSpin = SP621EEffect(
        name: "Blue Comet Spin",
        id: 0x7B,
        type: .standard
    )
    public static let yellowCometSpin = SP621EEffect(
        name: "Yellow Comet Spin",
        id: 0x7C,
        type: .standard
    )
    public static let cyanCometSpin = SP621EEffect(
        name: "Cyan Comet Spin",
        id: 0x7D,
        type: .standard
    )
    public static let purpleCometSpin = SP621EEffect(
        name: "Purple Comet Spin",
        id: 0x7E,
        type: .standard
    )
    public static let whiteCometSpin = SP621EEffect(
        name: "White Comet Spin",
        id: 0x7F,
        type: .standard
    )
    public static let redDotSpin = SP621EEffect(
        name: "Red Dot Spin",
        id: 0x80,
        type: .standard
    )
    public static let greenDotSpin = SP621EEffect(
        name: "Green Dot Spin",
        id: 0x81,
        type: .standard
    )
    public static let blueDotSpin = SP621EEffect(
        name: "Blue Dot Spin",
        id: 0x82,
        type: .standard
    )
    public static let yellowDotSpin = SP621EEffect(
        name: "Yellow Dot Spin",
        id: 0x83,
        type: .standard
    )
    public static let cyanDotSpin = SP621EEffect(
        name: "Cyan Dot Spin",
        id: 0x84,
        type: .standard
    )
    public static let purpleDotSpin = SP621EEffect(
        name: "Purple Dot Spin",
        id: 0x85,
        type: .standard
    )
    public static let whiteDotSpin = SP621EEffect(
        name: "White Dot Spin",
        id: 0x86,
        type: .standard
    )
    public static let redSegmentSpin = SP621EEffect(
        name: "Red Segment Spin",
        id: 0x87,
        type: .standard
    )
    public static let greenSegmentSpin = SP621EEffect(
        name: "Green Segment Spin",
        id: 0x88,
        type: .standard
    )
    public static let blueSegmentSpin = SP621EEffect(
        name: "Blue Segment Spin",
        id: 0x89,
        type: .standard
    )
    public static let yellowSegmentSpin = SP621EEffect(
        name: "Yellow Segment Spin",
        id: 0x8A,
        type: .standard
    )
    public static let cyanSegmentSpin = SP621EEffect(
        name: "Cyan Segment Spin",
        id: 0x8B,
        type: .standard
    )
    public static let purpleSegmentSpin = SP621EEffect(
        name: "Purple Segment Spin",
        id: 0x8C,
        type: .standard
    )
    public static let whiteSegmentSpin = SP621EEffect(
        name: "White Segment Spin",
        id: 0x8D,
        type: .standard
    )
    public static let gradient = SP621EEffect(
        name: "Gradient",
        id: 0x8E,
        type: .standard
    )
    
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
    public static let redWhiteBlue = SP621EEffect(
        name: "Red, White, and Blue",
        id: 0xD7,
        type: .audio
    )
    public static let festive = SP621EEffect(
        name: "Festive",
        id: 0xD8,
        type: .audio
    )
    public static let flames = SP621EEffect(
        name: "Flames",
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
        rainbowMeteor,
        rainbowStars,
        rainbowSpin,
        redYellowFire,
        redPurpleFire,
        greenYellowFire,
        greenCyanFire,
        bluePurpleFire,
        blueCyanFire,
        redComet,
        greenComet,
        blueComet,
        yellowComet,
        cyanComet,
        purpleComet,
        whiteComet,
        redMeteor,
        greenMeteor,
        blueMeteor,
        yellowMeteor,
        cyanMeteor,
        purpleMeteor,
        whiteMeteor,
        redGreenGradientSnake,
        redBlueGradientSnake,
        redYellowGradientSnake,
        redCyanGradientSnake,
        redPurpleGradientSnake,
        redWhiteGradientSnake,
        greenBlueGradientSnake,
        greenYellowGradientSnake,
        greenCyanGradientSnake,
        greenPurpleGradientSnake,
        greenWhiteGradientSnake,
        blueYellowGradientSnake,
        blueCyanGradientSnake,
        bluePurpleGradientSnake,
        blueWhiteGradientSnake,
        yellowCyanGradientSnake,
        yellowPurpleGradientSnake,
        yellowWhiteGradientSnake,
        cyanPurpleGradientSnake,
        cyanWhiteGradientSnake,
        purpleWhiteGradientSnake,
        redWave,
        greenWave,
        blueWave,
        yellowWave,
        cyanWave,
        purpleWave,
        whiteWave,
        redGreenWave,
        redBlueWave,
        redYellowWave,
        redCyanWave,
        redPurpleWave,
        redWhiteWave,
        greenBlueWave,
        greenYellowWave,
        greenCyanWave,
        greenPurpleWave,
        greenWhiteWave,
        blueYellowWave,
        blueCyanWave,
        bluePurpleWave,
        blueWhiteWave,
        yellowCyanWave,
        yellowPurpleWave,
        yellowWhiteWave,
        cyanPurpleWave,
        cyanWhiteWave,
        purpleWhiteWave,
        redStars,
        greenStars,
        blueStars,
        yellowStars,
        cyanStars,
        purpleStars,
        whiteStars,
        redTwinklingStars,
        greenTwinklingStars,
        blueTwinklingStars,
        yellowTwinklingStars,
        cyanTwinklingStars,
        purpleTwinklingStars,
        redWhiteTwinklingStars,
        greenWhiteTwinklingStars,
        blueWhiteTwinklingStars,
        yellowWhiteTwinklingStars,
        cyanWhiteTwinklingStars,
        purpleWhiteTwinklingStars,
        whiteTwinklingStars,
        redBreath,
        greenBreath,
        blueBreath,
        yellowBreath,
        cyanBreath,
        purpleBreath,
        whiteBreath,
        redStack,
        greenStack,
        blueStack,
        yellowStack,
        cyanStack,
        purpleStack,
        whiteStack,
        fullColorStack,
        redGreenStack,
        greenBlueStack,
        blueYellowStack,
        yellowCyanStack,
        cyanPurpleStack,
        purpleWhiteStack,
        redWhiteBlueSnake,
        greenWhiteYellowSnake,
        redGreenWhiteSnake,
        redYellowSnake,
        redWhiteSnake,
        greenWhiteSnake,
        redCometSpin,
        greenCometSpin,
        blueCometSpin,
        yellowCometSpin,
        cyanCometSpin,
        purpleCometSpin,
        whiteCometSpin,
        redDotSpin,
        greenDotSpin,
        blueDotSpin,
        yellowDotSpin,
        cyanDotSpin,
        purpleDotSpin,
        whiteDotSpin,
        redSegmentSpin,
        greenSegmentSpin,
        blueSegmentSpin,
        yellowSegmentSpin,
        cyanSegmentSpin,
        purpleSegmentSpin,
        whiteSegmentSpin,
        gradient,
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
        redWhiteBlue,
        festive,
        flames,
        party
    ]
    
    private static let combined: [SP621EEffect] = effects + [.none]
    private static let allEffects: [UInt8: SP621EEffect] = Dictionary(
        uniqueKeysWithValues: combined.map { ($0.id, $0) }
    )
}
