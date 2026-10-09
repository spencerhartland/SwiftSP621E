//
//  Logger.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/24/26.
//

import os

extension Logger {
    private static let subsystem = "com.spencerhartland.SwiftSP621E"
    
    private struct Category {
        static let bluetooth = "bluetooth"
        static let persistence = "persistence"
        static let audio = "audio"
    }
    
    internal static let bluetooth = Logger(subsystem: subsystem, category: Category.bluetooth)
    internal static let persistence = Logger(subsystem: subsystem, category: Category.persistence)
    internal static let audio = Logger(subsystem: subsystem, category: Category.audio)
}
