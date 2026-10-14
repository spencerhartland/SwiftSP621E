//
//  EffectsStore.swift
//  Harness
//
//  Created by Spencer Hartland on 9/13/26.
//

import Foundation
import os

@MainActor
@Observable
public final class EffectsStore {
    private static let recentEffectKey: String = "recentEffect"
    private static let recentAudioEffectKey: String = "recentAudioEffect"
    private static let favoriteEffectsKey: String = "favoriteEffects"
    private static let effectPresetsKey: String = "effectPresets"
    
    private let defaults: UserDefaults = UserDefaults.shared
    
    public private(set) var recentEffect: SP621EEffect?
    public private(set) var recentAudioEffect: SP621EEffect?
    
    private var favoriteEffects: Set<SP621EEffect> = []
    
    public var allFavoriteEffects: [SP621EEffect] {
        [SP621EEffect](favoriteEffects).sorted { $0.name < $1.name }
    }
    public var favoriteStandardEffects: [SP621EEffect] {
        allFavoriteEffects.filter { $0.type == .standard }
    }
    public var favoriteAudioEffects: [SP621EEffect] {
        allFavoriteEffects.filter { $0.type == .audio }
    }
    
    private var effectPresets: [UUID: EffectPreset] = [:]
    
    public var allPresets: [EffectPreset] {
        [EffectPreset](effectPresets.values).sorted { $0.name < $1.name }
    }
    public var standardPresets: [EffectPreset] {
        allPresets.filter { $0.effect.type == .standard }
    }
    public var audioPresets: [EffectPreset] {
        allPresets.filter { $0.effect.type == .audio }
    }
    
    public init() {
        self.recentEffect = getValue(SP621EEffect.self, forKey: Self.recentEffectKey)
        self.recentAudioEffect = getValue(SP621EEffect.self, forKey: Self.recentAudioEffectKey)
        self.favoriteEffects = getValue(
            Set<SP621EEffect>.self,
            forKey: Self.favoriteEffectsKey
        ) ?? []
        self.effectPresets = getValue(
            [UUID: EffectPreset].self,
            forKey: Self.effectPresetsKey
        ) ?? [:]
    }
    
    public func addFavoriteEffect(_ effect: SP621EEffect) {
        self.favoriteEffects.insert(effect)
        updateValue(self.favoriteEffects, forKey: Self.favoriteEffectsKey)
    }
    
    public func removeFavoriteEffect(_ effect: SP621EEffect) {
        self.favoriteEffects.remove(effect)
        updateValue(self.favoriteEffects, forKey: Self.favoriteEffectsKey)
    }
    
    public func saveRecentlyUsedEffect(_ effect: SP621EEffect) {
        switch effect.type {
        case .standard:
            self.recentEffect = effect
            updateValue(self.recentEffect, forKey: Self.recentEffectKey)
        case .audio:
            self.recentAudioEffect = effect
            updateValue(self.recentAudioEffect, forKey: Self.recentAudioEffectKey)
        }
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
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            let description = String(describing: error)
            Logger.persistence.error(
                """
                EffectsStore.updateValue(_:forKey:) - An error occurred while encoding the \
                specified value: \(description)
                """
            )
        }
    }
    
    private func getValue<T>(_ type: T.Type, forKey key: String) -> T? where T: Decodable {
        do {
            guard let data = defaults.data(forKey: key) else {
                Logger.persistence.info(
                    """
                    EffectsStore.getValue(_:forKey:) - The specified key did not return data.
                    """
                )
                return nil
            }
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let description = String(describing: error)
            Logger.persistence.info(
                    """
                    EffectsStore.getValue(_:forKey:) - An error occurred while decodig the \
                    specified value: \(description)
                    """
            )
            return nil
        }
    }
}
