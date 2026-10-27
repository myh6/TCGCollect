//
//  RemoteCardFixture.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Domain

/// A card as the backend sends it, with the card and price it should map to.
struct RemoteCardFixture {
    let card: Card
    let price: PricePoint
    var json: [String: Any]
}

/// Optional values are sent as null, like the backend does.
func makeRemoteCard(
    id: Int,
    name: String,
    number: String? = nil,
    setID: Int? = nil,
    setName: String? = nil,
    imageURL: URL? = nil,
    rarity: String? = nil,
    printing: String? = nil,
    price: String = "9.99",
    currency: String = "USD",
    fetchedAt: (date: Date, iso8601: String) = (Date(timeIntervalSince1970: 1_767_225_600), "2026-01-01T00:00:00+00:00")
) -> RemoteCardFixture {
    let card = Card(
        id: id,
        name: name,
        number: number,
        setID: setID,
        setName: setName,
        imageURL: imageURL,
        rarity: rarity,
        printing: printing
    )
    let pricePoint = PricePoint(
        cardID: id,
        date: fetchedAt.date,
        price: Money(amount: Decimal(string: price)!, currencyCode: currency)
    )
    let json: [String: Any] = [
        "card_id": id,
        "name": name,
        "number": number ?? NSNull(),
        "image_url": imageURL?.absoluteString ?? NSNull(),
        "set_id": setID ?? NSNull(),
        "set_name": setName ?? NSNull(),
        "rarity": rarity ?? NSNull(),
        "printing": printing ?? NSNull(),
        "game_slug": "one-piece-card-game",
        "current_price": price,
        "current_fetched_at": fetchedAt.iso8601,
        "currency": currency,
        "details": NSNull(),
        "pct_change": NSNull(),
        "baseline_price": NSNull(),
        "baseline_fetched_at": NSNull(),
    ]
    return RemoteCardFixture(card: card, price: pricePoint, json: json)
}
