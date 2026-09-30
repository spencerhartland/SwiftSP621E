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
    case audioSync = "Audio Sync"
    
    public init?(from effectID: UInt8) {
        let effect = SP621EEffect(id: effectID)
        
        if SP621EEffect.standardEffects.contains(effect) {
            self.init(rawValue: SP621EMode.dynamicEffect.rawValue)
        } else if SP621EEffect.audioEffects.contains(effect) {
            self.init(rawValue: SP621EMode.audioSync.rawValue)
        } else {
            self.init(rawValue: SP621EMode.solidColor.rawValue)
        }
    }
}
