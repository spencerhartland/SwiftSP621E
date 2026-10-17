//
//  SP621EEffect.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

import SwiftUI

public struct SP621EEffect: Identifiable, Sendable, Hashable {
    public enum Pattern: String, Sendable, Hashable, Codable, Identifiable {
        case rainbow = "Rainbow"
        case fire = "Fire"
        case comet = "Comet"
        case meteor = "Meteor"
        case gradientSnake = "Gradient Snake"
        case wave = "Wave"
        case stars = "Stars"
        case twinklingStars = "Twinkling Stars"
        case breath = "Breath"
        case stack = "Stack"
        case snake = "Snake"
        case cometSpin = "Comet Spin"
        case dotSpin = "Dot Spin"
        case segmentSpin = "Segment Spin"
        
        case rhythmSpectrum = "Rhythm Spectrum"
        case rhythmStars = "Rhythm Stars"
        case energy = "Energy"
        case pulse = "Pulse"
        case ejectionForward = "Ejection Forward"
        case ejectionBackward = "Ejection Backward"
        case vuMeter = "VU Meter"
        case redWhiteBlue = "Red, White, and Blue"
        case festive = "Festive"
        case flames = "Flames"
        case party = "Party"
        
        public var id: String { self.rawValue }
        public var name: String { self.rawValue }
        
        public static let standardPatterns: [Pattern] = [
            rainbow,
            fire,
            comet,
            meteor,
            gradientSnake,
            wave,
            stars,
            twinklingStars,
            breath,
            stack,
            snake,
            cometSpin,
            dotSpin,
            segmentSpin,
        ]
        
        public static let audioPatterns: [Pattern] = [
            rhythmSpectrum,
            rhythmStars,
            energy,
            pulse,
            ejectionForward,
            ejectionBackward,
            vuMeter,
            redWhiteBlue,
            festive,
            flames,
            party,
        ]
    }
    
    public enum StandardColor: String, Sendable, Hashable, Codable, Identifiable, CaseIterable {
        case red = "Red"
        case green = "Green"
        case blue = "Blue"
        case yellow = "Yellow"
        case cyan = "Cyan"
        case purple = "Purple"
        case white = "White"
        
        public var id: String { self.rawValue }
        public var name: String { self.rawValue }
        
        public var color: Color {
            switch self {
            case .red: .red
            case .green: .green
            case .blue: .blue
            case .yellow: .yellow
            case .cyan: .cyan
            case .purple: .purple
            case .white: .white
            }
        }
    }
    
    public enum EffectType: Sendable, Codable {
        case standard
        case audio
    }
    
    public let id: UInt8
    public let name: String
    public let type: EffectType
    public let pattern: Pattern?
    public let palette: [StandardColor]?
    
    init(id: UInt8, type: EffectType = .standard) {
        self = Self.allEffects[id] ?? .init(
            "Effect \(id)",
            id: id,
            type: type,
            pattern: nil,
            palette: nil
        )
    }
    
    init(
        _ name: String,
        id: UInt8,
        type: EffectType,
        pattern: Pattern? = nil,
        palette: [StandardColor]? = nil,
    ) {
        self.name = name
        self.id = id
        self.type = type
        self.pattern = pattern
        self.palette = palette
    }
    
    init(
        _ name: String? = nil,
        id: UInt8,
        type: EffectType,
        pattern: Pattern,
        palette: [StandardColor]? = nil,
    ) {
        self.name = name ?? Self.derivedName(palette: palette, pattern: pattern)
        self.id = id
        self.type = type
        self.pattern = pattern
        self.palette = palette
    }
    
    private static func derivedName(palette: [StandardColor]?, pattern: Pattern) -> String {
        if let palette {
            let prefix = palette.map(\.rawValue).joined(separator: "-")
            return "\(prefix) \(pattern.name)"
        } else {
            return pattern.name
        }
    }
}

extension SP621EEffect {
    // None: turns off effects
    public static let none = SP621EEffect("None", id: 0xBE, type: .standard)
    
    // Dynamic Effects: looping animations (0x01 - 0x8E)
    public static let rainbow = SP621EEffect(
        id: 0x01,
        type: .standard,
        pattern: .rainbow,
    )
    public static let rainbowMeteor = SP621EEffect(
        "Rainbow Meteor",
        id: 0x02,
        type: .standard,
        pattern: .rainbow,
    )
    public static let rainbowStars = SP621EEffect(
        "Rainbow Stars",
        id: 0x03,
        type: .standard,
        pattern: .rainbow,
    )
    public static let rainbowSpin = SP621EEffect(
        "Rainbow Spin",
        id: 0x04,
        type: .standard,
        pattern: .rainbow,
    )
    public static let redYellowFire = SP621EEffect(
        id: 0x05,
        type: .standard,
        pattern: .fire,
        palette: [.red, .yellow],
    )
    public static let redPurpleFire = SP621EEffect(
        id: 0x06,
        type: .standard,
        pattern: .fire,
        palette: [.red, .purple],
    )
    public static let greenYellowFire = SP621EEffect(
        id: 0x07,
        type: .standard,
        pattern: .fire,
        palette: [.green, .yellow],
    )
    public static let greenCyanFire = SP621EEffect(
        id: 0x08,
        type: .standard,
        pattern: .fire,
        palette: [.green, .cyan],
    )
    public static let bluePurpleFire = SP621EEffect(
        id: 0x09,
        type: .standard,
        pattern: .fire,
        palette: [.blue, .purple],
    )
    public static let blueCyanFire = SP621EEffect(
        id: 0x0A,
        type: .standard,
        pattern: .fire,
        palette: [.blue, .cyan],
    )
    public static let redComet = SP621EEffect(
        id: 0x0B,
        type: .standard,
        pattern: .comet,
        palette: [.red],
    )
    public static let greenComet = SP621EEffect(
        id: 0x0C,
        type: .standard,
        pattern: .comet,
        palette: [.green],
    )
    public static let blueComet = SP621EEffect(
        id: 0x0D,
        type: .standard,
        pattern: .comet,
        palette: [.blue],
    )
    public static let yellowComet = SP621EEffect(
        id: 0x0E,
        type: .standard,
        pattern: .comet,
        palette: [.yellow],
    )
    public static let cyanComet = SP621EEffect(
        id: 0x0F,
        type: .standard,
        pattern: .comet,
        palette: [.cyan],
    )
    public static let purpleComet = SP621EEffect(
        id: 0x10,
        type: .standard,
        pattern: .comet,
        palette: [.purple],
    )
    public static let whiteComet = SP621EEffect(
        id: 0x11,
        type: .standard,
        pattern: .comet,
        palette: [.white],
    )
    public static let redMeteor = SP621EEffect(
        id: 0x12,
        type: .standard,
        pattern: .meteor,
        palette: [.red],
    )
    public static let greenMeteor = SP621EEffect(
        id: 0x13,
        type: .standard,
        pattern: .meteor,
        palette: [.green],
    )
    public static let blueMeteor = SP621EEffect(
        id: 0x14,
        type: .standard,
        pattern: .meteor,
        palette: [.blue],
    )
    public static let yellowMeteor = SP621EEffect(
        id: 0x15,
        type: .standard,
        pattern: .meteor,
        palette: [.yellow],
    )
    public static let cyanMeteor = SP621EEffect(
        id: 0x16,
        type: .standard,
        pattern: .meteor,
        palette: [.cyan],
    )
    public static let purpleMeteor = SP621EEffect(
        id: 0x17,
        type: .standard,
        pattern: .meteor,
        palette: [.purple],
    )
    public static let whiteMeteor = SP621EEffect(
        id: 0x18,
        type: .standard,
        pattern: .meteor,
        palette: [.white],
    )
    public static let redGreenGradientSnake = SP621EEffect(
        id: 0x19,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.red, .green],
    )
    public static let redBlueGradientSnake = SP621EEffect(
        id: 0x1A,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.red, .blue],
    )
    public static let redYellowGradientSnake = SP621EEffect(
        id: 0x1B,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.red, .yellow],
    )
    public static let redCyanGradientSnake = SP621EEffect(
        id: 0x1C,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.red, .cyan],
    )
    public static let redPurpleGradientSnake = SP621EEffect(
        id: 0x1D,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.red, .purple],
    )
    public static let redWhiteGradientSnake = SP621EEffect(
        id: 0x1E,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.red, .white],
    )
    public static let greenBlueGradientSnake = SP621EEffect(
        id: 0x1F,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.green, .blue],
    )
    public static let greenYellowGradientSnake = SP621EEffect(
        id: 0x20,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.green, .yellow],
    )
    public static let greenCyanGradientSnake = SP621EEffect(
        id: 0x21,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.green, .cyan],
    )
    public static let greenPurpleGradientSnake = SP621EEffect(
        id: 0x22,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.green, .purple],
    )
    public static let greenWhiteGradientSnake = SP621EEffect(
        id: 0x23,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.green, .white],
    )
    public static let blueYellowGradientSnake = SP621EEffect(
        id: 0x24,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.blue, .yellow],
    )
    public static let blueCyanGradientSnake = SP621EEffect(
        id: 0x25,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.blue, .cyan],
    )
    public static let bluePurpleGradientSnake = SP621EEffect(
        id: 0x26,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.blue, .purple],
    )
    public static let blueWhiteGradientSnake = SP621EEffect(
        id: 0x27,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.blue, .white],
    )
    public static let yellowCyanGradientSnake = SP621EEffect(
        id: 0x28,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.yellow, .cyan],
    )
    public static let yellowPurpleGradientSnake = SP621EEffect(
        id: 0x29,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.yellow, .purple],
    )
    public static let yellowWhiteGradientSnake = SP621EEffect(
        id: 0x2A,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.yellow, .white],
    )
    public static let cyanPurpleGradientSnake = SP621EEffect(
        id: 0x2B,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.cyan, .purple],
    )
    public static let cyanWhiteGradientSnake = SP621EEffect(
        id: 0x2C,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.cyan, .white],
    )
    public static let purpleWhiteGradientSnake = SP621EEffect(
        id: 0x2D,
        type: .standard,
        pattern: .gradientSnake,
        palette: [.purple, .white],
    )
    public static let redWave = SP621EEffect(
        id: 0x2E,
        type: .standard,
        pattern: .wave,
        palette: [.red],
    )
    public static let greenWave = SP621EEffect(
        id: 0x2F,
        type: .standard,
        pattern: .wave,
        palette: [.green],
    )
    public static let blueWave = SP621EEffect(
        id: 0x30,
        type: .standard,
        pattern: .wave,
        palette: [.blue],
    )
    public static let yellowWave = SP621EEffect(
        id: 0x31,
        type: .standard,
        pattern: .wave,
        palette: [.yellow],
    )
    public static let cyanWave = SP621EEffect(
        id: 0x32,
        type: .standard,
        pattern: .wave,
        palette: [.cyan],
    )
    public static let purpleWave = SP621EEffect(
        id: 0x33,
        type: .standard,
        pattern: .wave,
        palette: [.purple],
    )
    public static let whiteWave = SP621EEffect(
        id: 0x34,
        type: .standard,
        pattern: .wave,
        palette: [.white],
    )
    public static let redGreenWave = SP621EEffect(
        id: 0x35,
        type: .standard,
        pattern: .wave,
        palette: [.red, .green],
    )
    public static let redBlueWave = SP621EEffect(
        id: 0x36,
        type: .standard,
        pattern: .wave,
        palette: [.red, .blue],
    )
    public static let redYellowWave = SP621EEffect(
        id: 0x37,
        type: .standard,
        pattern: .wave,
        palette: [.red, .yellow],
    )
    public static let redCyanWave = SP621EEffect(
        id: 0x38,
        type: .standard,
        pattern: .wave,
        palette: [.red, .cyan],
    )
    public static let redPurpleWave = SP621EEffect(
        id: 0x39,
        type: .standard,
        pattern: .wave,
        palette: [.red, .purple],
    )
    public static let redWhiteWave = SP621EEffect(
        id: 0x3A,
        type: .standard,
        pattern: .wave,
        palette: [.red, .white],
    )
    public static let greenBlueWave = SP621EEffect(
        id: 0x3B,
        type: .standard,
        pattern: .wave,
        palette: [.green, .blue],
    )
    public static let greenYellowWave = SP621EEffect(
        id: 0x3C,
        type: .standard,
        pattern: .wave,
        palette: [.green, .yellow],
    )
    public static let greenCyanWave = SP621EEffect(
        id: 0x3D,
        type: .standard,
        pattern: .wave,
        palette: [.green, .cyan],
    )
    public static let greenPurpleWave = SP621EEffect(
        id: 0x3E,
        type: .standard,
        pattern: .wave,
        palette: [.green, .purple],
    )
    public static let greenWhiteWave = SP621EEffect(
        id: 0x3F,
        type: .standard,
        pattern: .wave,
        palette: [.green, .white],
    )
    public static let blueYellowWave = SP621EEffect(
        id: 0x40,
        type: .standard,
        pattern: .wave,
        palette: [.blue, .yellow],
    )
    public static let blueCyanWave = SP621EEffect(
        id: 0x41,
        type: .standard,
        pattern: .wave,
        palette: [.blue, .cyan],
    )
    public static let bluePurpleWave = SP621EEffect(
        id: 0x42,
        type: .standard,
        pattern: .wave,
        palette: [.blue, .purple],
    )
    public static let blueWhiteWave = SP621EEffect(
        id: 0x43,
        type: .standard,
        pattern: .wave,
        palette: [.blue, .white],
    )
    public static let yellowCyanWave = SP621EEffect(
        id: 0x44,
        type: .standard,
        pattern: .wave,
        palette: [.yellow, .cyan],
    )
    public static let yellowPurpleWave = SP621EEffect(
        id: 0x45,
        type: .standard,
        pattern: .wave,
        palette: [.yellow, .purple],
    )
    public static let yellowWhiteWave = SP621EEffect(
        id: 0x46,
        type: .standard,
        pattern: .wave,
        palette: [.yellow, .white],
    )
    public static let cyanPurpleWave = SP621EEffect(
        id: 0x47,
        type: .standard,
        pattern: .wave,
        palette: [.cyan, .purple],
    )
    public static let cyanWhiteWave = SP621EEffect(
        id: 0x48,
        type: .standard,
        pattern: .wave,
        palette: [.cyan, .white],
    )
    public static let purpleWhiteWave = SP621EEffect(
        id: 0x49,
        type: .standard,
        pattern: .wave,
        palette: [.purple, .white],
    )
    public static let redStars = SP621EEffect(
        id: 0x4A,
        type: .standard,
        pattern: .stars,
        palette: [.red],
    )
    public static let greenStars = SP621EEffect(
        id: 0x4B,
        type: .standard,
        pattern: .stars,
        palette: [.green],
    )
    public static let blueStars = SP621EEffect(
        id: 0x4C,
        type: .standard,
        pattern: .stars,
        palette: [.blue],
    )
    public static let yellowStars = SP621EEffect(
        id: 0x4D,
        type: .standard,
        pattern: .stars,
        palette: [.yellow],
    )
    public static let cyanStars = SP621EEffect(
        id: 0x4E,
        type: .standard,
        pattern: .stars,
        palette: [.cyan],
    )
    public static let purpleStars = SP621EEffect(
        id: 0x4F,
        type: .standard,
        pattern: .stars,
        palette: [.purple],
    )
    public static let whiteStars = SP621EEffect(
        id: 0x50,
        type: .standard,
        pattern: .stars,
        palette: [.white],
    )
    public static let redTwinklingStars = SP621EEffect(
        id: 0x51,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.red],
    )
    public static let greenTwinklingStars = SP621EEffect(
        id: 0x52,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.green],
    )
    public static let blueTwinklingStars = SP621EEffect(
        id: 0x53,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.blue],
    )
    public static let yellowTwinklingStars = SP621EEffect(
        id: 0x54,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.yellow],
    )
    public static let cyanTwinklingStars = SP621EEffect(
        id: 0x55,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.cyan],
    )
    public static let purpleTwinklingStars = SP621EEffect(
        id: 0x56,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.purple],
    )
    public static let redWhiteTwinklingStars = SP621EEffect(
        id: 0x57,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.red, .white],
    )
    public static let greenWhiteTwinklingStars = SP621EEffect(
        id: 0x58,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.green, .white],
    )
    public static let blueWhiteTwinklingStars = SP621EEffect(
        id: 0x59,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.blue, .white],
    )
    public static let yellowWhiteTwinklingStars = SP621EEffect(
        id: 0x5A,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.yellow, .white],
    )
    public static let cyanWhiteTwinklingStars = SP621EEffect(
        id: 0x5B,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.cyan, .white],
    )
    public static let purpleWhiteTwinklingStars = SP621EEffect(
        id: 0x5C,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.purple, .white],
    )
    public static let whiteTwinklingStars = SP621EEffect(
        id: 0x5D,
        type: .standard,
        pattern: .twinklingStars,
        palette: [.white],
    )
    public static let redBreath = SP621EEffect(
        id: 0x5E,
        type: .standard,
        pattern: .breath,
        palette: [.red],
    )
    public static let greenBreath = SP621EEffect(
        id: 0x5F,
        type: .standard,
        pattern: .breath,
        palette: [.green],
    )
    public static let blueBreath = SP621EEffect(
        id: 0x60,
        type: .standard,
        pattern: .breath,
        palette: [.blue],
    )
    public static let yellowBreath = SP621EEffect(
        id: 0x61,
        type: .standard,
        pattern: .breath,
        palette: [.yellow],
    )
    public static let cyanBreath = SP621EEffect(
        id: 0x62,
        type: .standard,
        pattern: .breath,
        palette: [.cyan],
    )
    public static let purpleBreath = SP621EEffect(
        id: 0x63,
        type: .standard,
        pattern: .breath,
        palette: [.purple],
    )
    public static let whiteBreath = SP621EEffect(
        id: 0x64,
        type: .standard,
        pattern: .breath,
        palette: [.white],
    )
    public static let redStack = SP621EEffect(
        id: 0x65,
        type: .standard,
        pattern: .stack,
        palette: [.red],
    )
    public static let greenStack = SP621EEffect(
        id: 0x66,
        type: .standard,
        pattern: .stack,
        palette: [.green],
    )
    public static let blueStack = SP621EEffect(
        id: 0x67,
        type: .standard,
        pattern: .stack,
        palette: [.blue],
    )
    public static let yellowStack = SP621EEffect(
        id: 0x68,
        type: .standard,
        pattern: .stack,
        palette: [.yellow],
    )
    public static let cyanStack = SP621EEffect(
        id: 0x69,
        type: .standard,
        pattern: .stack,
        palette: [.cyan],
    )
    public static let purpleStack = SP621EEffect(
        id: 0x6A,
        type: .standard,
        pattern: .stack,
        palette: [.purple],
    )
    public static let whiteStack = SP621EEffect(
        id: 0x6B,
        type: .standard,
        pattern: .stack,
        palette: [.white],
    )
    public static let fullColorStack = SP621EEffect(
        "Full Color Stack",
        id: 0x6C,
        type: .standard,
        pattern: .stack,
    )
    public static let redGreenStack = SP621EEffect(
        id: 0x6D,
        type: .standard,
        pattern: .stack,
        palette: [.red, .green],
    )
    public static let greenBlueStack = SP621EEffect(
        id: 0x6E,
        type: .standard,
        pattern: .stack,
        palette: [.green, .blue],
    )
    public static let blueYellowStack = SP621EEffect(
        id: 0x6F,
        type: .standard,
        pattern: .stack,
        palette: [.blue, .yellow],
    )
    public static let yellowCyanStack = SP621EEffect(
        id: 0x70,
        type: .standard,
        pattern: .stack,
        palette: [.yellow, .cyan],
    )
    public static let cyanPurpleStack = SP621EEffect(
        id: 0x71,
        type: .standard,
        pattern: .stack,
        palette: [.cyan, .purple],
    )
    public static let purpleWhiteStack = SP621EEffect(
        id: 0x72,
        type: .standard,
        pattern: .stack,
        palette: [.purple, .white],
    )
    public static let redWhiteBlueSnake = SP621EEffect(
        id: 0x73,
        type: .standard,
        pattern: .snake,
        palette: [.red, .white, .blue],
    )
    public static let greenWhiteYellowSnake = SP621EEffect(
        id: 0x74,
        type: .standard,
        pattern: .snake,
        palette: [.green, .white, .yellow],
    )
    public static let redGreenWhiteSnake = SP621EEffect(
        id: 0x75,
        type: .standard,
        pattern: .snake,
        palette: [.red, .green, .white],
    )
    public static let redYellowSnake = SP621EEffect(
        id: 0x76,
        type: .standard,
        pattern: .snake,
        palette: [.red, .yellow],
    )
    public static let redWhiteSnake = SP621EEffect(
        id: 0x77,
        type: .standard,
        pattern: .snake,
        palette: [.red, .white],
    )
    public static let greenWhiteSnake = SP621EEffect(
        id: 0x78,
        type: .standard,
        pattern: .snake,
        palette: [.green, .white],
    )
    public static let redCometSpin = SP621EEffect(
        id: 0x79,
        type: .standard,
        pattern: .cometSpin,
        palette: [.red],
    )
    public static let greenCometSpin = SP621EEffect(
        id: 0x7A,
        type: .standard,
        pattern: .cometSpin,
        palette: [.green],
    )
    public static let blueCometSpin = SP621EEffect(
        id: 0x7B,
        type: .standard,
        pattern: .cometSpin,
        palette: [.blue],
    )
    public static let yellowCometSpin = SP621EEffect(
        id: 0x7C,
        type: .standard,
        pattern: .cometSpin,
        palette: [.yellow],
    )
    public static let cyanCometSpin = SP621EEffect(
        id: 0x7D,
        type: .standard,
        pattern: .cometSpin,
        palette: [.cyan],
    )
    public static let purpleCometSpin = SP621EEffect(
        id: 0x7E,
        type: .standard,
        pattern: .cometSpin,
        palette: [.purple],
    )
    public static let whiteCometSpin = SP621EEffect(
        id: 0x7F,
        type: .standard,
        pattern: .cometSpin,
        palette: [.white],
    )
    public static let redDotSpin = SP621EEffect(
        id: 0x80,
        type: .standard,
        pattern: .dotSpin,
        palette: [.red],
    )
    public static let greenDotSpin = SP621EEffect(
        id: 0x81,
        type: .standard,
        pattern: .dotSpin,
        palette: [.green],
    )
    public static let blueDotSpin = SP621EEffect(
        id: 0x82,
        type: .standard,
        pattern: .dotSpin,
        palette: [.blue],
    )
    public static let yellowDotSpin = SP621EEffect(
        id: 0x83,
        type: .standard,
        pattern: .dotSpin,
        palette: [.yellow],
    )
    public static let cyanDotSpin = SP621EEffect(
        id: 0x84,
        type: .standard,
        pattern: .dotSpin,
        palette: [.cyan],
    )
    public static let purpleDotSpin = SP621EEffect(
        id: 0x85,
        type: .standard,
        pattern: .dotSpin,
        palette: [.purple],
    )
    public static let whiteDotSpin = SP621EEffect(
        id: 0x86,
        type: .standard,
        pattern: .dotSpin,
        palette: [.white],
    )
    public static let redSegmentSpin = SP621EEffect(
        id: 0x87,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.red],
    )
    public static let greenSegmentSpin = SP621EEffect(
        id: 0x88,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.green],
    )
    public static let blueSegmentSpin = SP621EEffect(
        id: 0x89,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.blue],
    )
    public static let yellowSegmentSpin = SP621EEffect(
        id: 0x8A,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.yellow],
    )
    public static let cyanSegmentSpin = SP621EEffect(
        id: 0x8B,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.cyan],
    )
    public static let purpleSegmentSpin = SP621EEffect(
        id: 0x8C,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.purple],
    )
    public static let whiteSegmentSpin = SP621EEffect(
        id: 0x8D,
        type: .standard,
        pattern: .segmentSpin,
        palette: [.white],
    )
    public static let gradient = SP621EEffect(
        "Gradient",
        id: 0x8E,
        type: .standard,
        pattern: .rainbow,
    )
    
    // Audio Effects: react to microphone audio
    public static let fullColorRhythmSpectrum = SP621EEffect(
        "Rhythm Spectrum (Multicolor)",
        id: 0xC9,
        type: .audio
    )
    public static let singleColorRhythmSpectrum = SP621EEffect(
        "Rhythm Spectrum (Single Color)",
        id: 0xCA,
        type: .audio
    )
    public static let fullColorRhythmStars = SP621EEffect(
        "Rhythm Stars (Multicolor)",
        id: 0xCB,
        type: .audio
    )
    public static let singleColorRhythmStars = SP621EEffect(
        "Rhythm Stars (Single Color)",
        id: 0xCC,
        type: .audio
    )
    public static let gradientEnergy = SP621EEffect(
        "Energy (Multicolor)",
        id: 0xCD,
        type: .audio
    )
    public static let singleColorEnergy = SP621EEffect(
        "Energy (Single Color)",
        id: 0xCE,
        type: .audio
    )
    public static let gradientPulse = SP621EEffect(
        "Pulse (Multicolor)",
        id: 0xCF,
        type: .audio
    )
    public static let singleColorPulse = SP621EEffect(
        "Pulse (Single Color)",
        id: 0xD0,
        type: .audio
    )
    public static let fullColorEjectionForward = SP621EEffect(
        "Ejection Forward (Multicolor)",
        id: 0xD1,
        type: .audio
    )
    public static let singleColorEjectionForward = SP621EEffect(
        "Ejection Forward (Single Color)",
        id: 0xD2,
        type: .audio
    )
    public static let fullColorEjectionBackward = SP621EEffect(
        "Ejection Backward (Multicolor)",
        id: 0xD3,
        type: .audio
    )
    public static let singleColorEjectionBackward = SP621EEffect(
        "Ejection Backward (Single Color)",
        id: 0xD4,
        type: .audio
    )
    public static let fullColorVUMeter = SP621EEffect(
        "VU Meter (Multicolor)",
        id: 0xD5,
        type: .audio
    )
    public static let singleColorVUMeter = SP621EEffect(
        "VU Meter (Single Color)",
        id: 0xD6,
        type: .audio
    )
    public static let redWhiteBlue = SP621EEffect(
        "Red, White, and Blue",
        id: 0xD7,
        type: .audio
    )
    public static let festive = SP621EEffect(
        "Festive",
        id: 0xD8,
        type: .audio
    )
    public static let flames = SP621EEffect(
        "Flames",
        id: 0xD9,
        type: .audio
    )
    public static let party = SP621EEffect(
        "Party",
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

extension SP621EEffect: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UInt8.self, forKey: .id)
        let type = try container.decodeIfPresent(EffectType.self, forKey: .type) ?? .standard
        self.init(id: id, type: type)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
    }
}
