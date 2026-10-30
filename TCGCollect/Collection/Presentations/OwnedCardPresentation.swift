//
//  OwnedCardPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import Foundation
import AppCore

/// What a collection tile shows for one owned card.
nonisolated struct OwnedCardPresentation: Identifiable, Equatable {
    /// The owned card's id, so two copies of the same card are two tiles.
    let id: OwnedCard.ID
    let name: String
    /// The card number and rarity, e.g. "OP01-001 · L", or nil when the card has neither.
    let details: String?
    let imageURL: URL?
    let card: Card

    init(_ ownedCard: OwnedCard) {
        id = ownedCard.id
        name = ownedCard.card.name
        details = ownedCard.card.numberAndRarity
        imageURL = ownedCard.card.imageURL
        card = ownedCard.card
    }
}
