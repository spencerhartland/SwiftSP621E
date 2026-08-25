//
//  RGB.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/13/26.
//

import SwiftUI

/// A color expressed as distinct red, green, and blue values.
public struct RGB: Equatable, Sendable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    
    public var color: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
    
    internal init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}
