//
//  SP621EMode.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/21/26.
//

/// A mode of operation which determines if the controller displays a solid color or
/// one of its built-in dynamic lighting effects.
public enum SP621EMode: String, Sendable {
    case solidColor = "Solid Color"
    case dynamicEffect = "Dynamic Effect"
}
