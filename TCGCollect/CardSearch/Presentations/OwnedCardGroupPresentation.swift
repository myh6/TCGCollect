//
//  OwnedCardGroupPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import AppCore

/// What a row shows for a card the user owns, once however many copies they have.
nonisolated struct OwnedCardGroupPresentation: Identifiable, Equatable {
    let id: Card.ID
    let name: String
    /// The card number and rarity, e.g. "OP01-001 · L", or nil when the card has neither.
    let details: String?
    /// How many copies the user owns, e.g. "×3".
    let copies: String
    let imageURL: URL?
    let card: Card

    init(_ group: OwnedCardGroup) {
        id = group.card.id
        name = group.card.name
        details = group.card.numberAndRarity
        copies = "×\(group.count)"
        imageURL = group.card.imageURL
        card = group.card
    }
}
