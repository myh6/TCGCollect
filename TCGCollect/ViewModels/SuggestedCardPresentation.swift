//
//  SuggestedCardPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Foundation
import AppCore

/// What a tile shows for a card suggested in a chat answer.
nonisolated struct SuggestedCardPresentation: Identifiable, Equatable {
    let id: Card.ID
    let name: String
    /// The card number and rarity, e.g. "OP01-001 · L", or nil when the backend sent neither.
    let details: String?
    let price: String
    let imageURL: URL?

    init(_ suggestion: ChatAnswer.Suggestion, locale: Locale = .current) {
        let card = suggestion.card
        let price = suggestion.price.price
        id = card.id
        name = card.name
        let detailParts = [card.number, card.rarity].compactMap { $0 }
        details = detailParts.isEmpty ? nil : detailParts.joined(separator: " · ")
        self.price = price.amount.formatted(.currency(code: price.currencyCode).locale(locale))
        imageURL = card.imageURL
    }
}
