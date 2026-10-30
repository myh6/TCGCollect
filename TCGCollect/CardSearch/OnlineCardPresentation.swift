//
//  OnlineCardPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import AppCore

/// What a row shows for a card found online.
nonisolated struct OnlineCardPresentation: Identifiable, Equatable {
    let id: Card.ID
    let name: String
    /// The card number and rarity, e.g. "OP01-001 · L", or nil when the backend sent neither.
    let details: String?
    /// The current price, or "No price" when the backend has none yet.
    let price: String
    let imageURL: URL?
    let card: Card

    init(_ result: CardSearchResult, locale: Locale = .current) {
        let card = result.card
        id = card.id
        name = card.name
        details = card.numberAndRarity
        price = result.price.map { pricePoint in
            pricePoint.price.amount.formatted(.currency(code: pricePoint.price.currencyCode).locale(locale))
        } ?? String(localized: "No price")
        imageURL = card.imageURL
        self.card = card
    }
}
