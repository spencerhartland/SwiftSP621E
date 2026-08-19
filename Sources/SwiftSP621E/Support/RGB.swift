//
//  RGB.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 7/13/26.
//

import SwiftUI

/// A color expressed as distinct red, green, and blue values.
internal struct RGB: Equatable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    
    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}
