//
//  Card+Details.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import AppCore

extension Card {
    /// The card number and rarity, e.g. "OP01-001 · L", or nil when the card has neither.
    nonisolated var numberAndRarity: String? {
        let parts = [number, rarity].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
