//
//  SP621EEffect.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

/// A dynamic lighting effect.
///
/// The SP621E has 142 built-in effects, each addrerssed by an 8-bit unsigned integer.
public enum SP621EEffect: UInt8, Sendable {
    case none = 0xBE
    case rainbow = 0x01
}
