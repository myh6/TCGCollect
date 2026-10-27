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
    let current_price: String
    let currency: String
    let current_fetched_at: Date

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

    /// nil when the price can't be read as a number.
    var price: PricePoint? {
        // A string, so it converts to Decimal exactly; a JSON number would go through Double first.
        guard let amount = Decimal(string: current_price, locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        return PricePoint(cardID: card_id, date: current_fetched_at, price: Money(amount: amount, currencyCode: currency))
    }
}
