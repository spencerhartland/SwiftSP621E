//
//  EffectsStore.swift
//  Harness
//
//  Created by Spencer Hartland on 9/13/26.
//

import Foundation

@MainActor
@Observable
public final class EffectsStore {
    private static let recentEffectKey: String = "recentEffect"
    private static let recentAudioEffectKey: String = "recentAudioEffect"
    private static let favoriteEffectsKey: String = "favoriteEffects"
    private static let favoriteAudioEffectsKey: String = "favoriteAudioEffects"
    private static let effectPresetsKey: String = "effectPresets"
    
    private let defaults: UserDefaults = UserDefaults.shared
    
    public private(set) var recentEffect: SP621EEffect?
    public private(set) var favoriteEffects: Set<SP621EEffect> = []
    private var effectPresets: [UUID: EffectPreset] = [:]
    public var presets: [EffectPreset] {
        [EffectPreset](effectPresets.values).sorted { $0.name < $1.name }
    }
    
    public private(set) var recentAudioEffect: SP621EEffect?
    public private(set) var favoriteAudioEffects: Set<SP621EEffect> = []
    // TODO: Implement audio effect presets
    
    public init() {
        self.recentEffect = getValue(SP621EEffect.self, forKey: Self.recentEffectKey)
        self.recentAudioEffect = getValue(SP621EEffect.self, forKey: Self.recentAudioEffectKey)
        self.favoriteEffects = getValue(
            Set<SP621EEffect>.self,
            forKey: Self.favoriteEffectsKey
        ) ?? []
        self.favoriteAudioEffects = getValue(
            Set<SP621EEffect>.self,
            forKey: Self.favoriteAudioEffectsKey
        ) ?? []
        self.effectPresets = getValue([UUID: EffectPreset].self, forKey: Self.effectPresetsKey) ?? [:]
    }
    
    public func favoriteEffect(_ effect: SP621EEffect) {
        self.favoriteEffects.insert(effect)
        updateValue(self.favoriteEffects, forKey: Self.favoriteEffectsKey)
    }
    
    public func favoriteAudioEffect(_ effect: SP621EEffect) {
        self.favoriteAudioEffects.insert(effect)
        updateValue(self.favoriteAudioEffects, forKey: Self.favoriteAudioEffectsKey)
    }
    
    public func unfavoriteEffect(_ effect: SP621EEffect) {
        self.favoriteEffects.remove(effect)
        updateValue(self.favoriteEffects, forKey: Self.favoriteEffectsKey)
    }
    
    public func unfavoriteAudioEffect(_ effect: SP621EEffect) {
        self.favoriteAudioEffects.remove(effect)
        updateValue(self.favoriteAudioEffects, forKey: Self.favoriteAudioEffectsKey)
    }
    
    public func saveRecentlyUsedEffect(_ effect: SP621EEffect) {
        self.recentEffect = effect
        updateValue(self.recentEffect, forKey: Self.recentEffectKey)
    }
    
    public func saveRecentlyUsedAudioEffect(_ effect: SP621EEffect) {
        self.recentAudioEffect = effect
        updateValue(self.recentAudioEffect, forKey: Self.recentAudioEffectKey)
    }
    
    public func savePreset(_ preset: EffectPreset) {
        self.effectPresets[preset.id] = preset
        updateValue(self.effectPresets, forKey: Self.effectPresetsKey)
    }
    
    public func deletePreset(_ preset: EffectPreset) {
        self.effectPresets[preset.id] = nil
        updateValue(self.effectPresets, forKey: Self.effectPresetsKey)
    }
    
    public func resetPresets() {
        self.effectPresets = [:]
        updateValue(self.effectPresets, forKey: Self.effectPresetsKey)
    }
    
    private func updateValue<T>(_ value: T, forKey key: String) where T: Encodable {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
    
    private func getValue<T>(_ type: T.Type, forKey key: String) -> T? where T: Decodable {
        guard let data = defaults.data(forKey: key),
              let decodedData = try? JSONDecoder().decode(type, from: data)
        else {
            return nil
        }
        
        return decodedData
    }
}
