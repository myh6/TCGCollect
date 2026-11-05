//
//  CardSetPage.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

public struct CardSetPage: Equatable, Sendable {
    public let cards: [CardSearchResult]
    public let totalCount: Int

    public init(cards: [CardSearchResult], totalCount: Int) {
        self.cards = cards
        self.totalCount = totalCount
    }
}
