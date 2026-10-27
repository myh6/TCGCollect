//
//  CardSearchResult.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

/// A card found by a search, with its latest price when the backend has one.
public struct CardSearchResult: Equatable, Sendable {
    public let card: Card
    public let price: PricePoint?

    public init(card: Card, price: PricePoint?) {
        self.card = card
        self.price = price
    }
}
