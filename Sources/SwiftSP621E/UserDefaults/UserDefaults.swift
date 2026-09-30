//
//  UserDefaults.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 9/28/26.
//

import Foundation

extension UserDefaults {
    private static let suiteName: String = "SwiftSP621E"
    internal static var shared: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }
}
