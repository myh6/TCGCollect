//
//  RemoteCard.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Domain

/// One card in the backend's shared card shape, as sent by /v1/ask and /v1/search.
/// `details` and the price-mover extras aren't mapped yet.
struct RemoteCard: Decodable {
    let card_id: Int
    let name: String
    let number: String?
    let image_url: URL?
    let set_id: Int?
    let set_name: String?
    let rarity: String?
    let printing: String?
    // Optional, and the date kept as text: a card without a usable price is still a valid card.
    let current_price: String?
    let currency: String?
    let current_fetched_at: String?

    var card: Card {
        Card(
            id: card_id,
            name: name,
            number: number,
            setID: set_id,
            setName: set_name,
            imageURL: image_url,
            rarity: rarity,
            printing: printing
        )
    }

    /// nil when any price value is missing or can't be read.
    var price: PricePoint? {
        guard let current_price, let currency, let current_fetched_at,
              // A string, so it converts to Decimal exactly; a JSON number would go through Double first.
              let amount = Decimal(string: current_price, locale: Locale(identifier: "en_US_POSIX")),
              let date = ISO8601DateFormatter().date(from: current_fetched_at) else { return nil }
        return PricePoint(cardID: card_id, date: date, price: Money(amount: amount, currencyCode: currency))
    }
}
