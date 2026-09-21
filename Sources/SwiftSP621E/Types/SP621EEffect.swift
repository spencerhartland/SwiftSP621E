//
//  SP621EEffect.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

/// A dynamic lighting effect.
///
/// The SP621E has 142 built-in effects, each addrerssed by an 8-bit unsigned integer.
public struct SP621EEffect: Identifiable, Sendable, Equatable, Hashable, Codable {
    public let name: String
    public let id: UInt8
    
    public init(id: UInt8) {
        self = Self.effects[id] ?? Self(name: "Effect \(id)", id: id)
    }
    
    private init(name: String, id: UInt8) {
        self.name = name
        self.id = id
    }
}

// 0x01 - 0x8E
extension SP621EEffect {
    public static let none = SP621EEffect(name: "None", id: 0xBE)
    public static let rainbow = SP621EEffect(name: "Rainbow", id: 0x01)
    public static let rainbow2 = SP621EEffect(name: "Rainbow 2", id: 0x02)
}

extension SP621EEffect: CaseIterable {
    public static let allCases: [SP621EEffect] = [.rainbow, .rainbow2]
    
    private static let effects: [UInt8: SP621EEffect] = Dictionary(uniqueKeysWithValues: (allCases + [.none]).map { ($0.id, $0) })
}
