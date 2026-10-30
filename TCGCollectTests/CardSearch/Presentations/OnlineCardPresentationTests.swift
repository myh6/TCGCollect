//
//  OnlineCardPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct OnlineCardPresentationTests {

    @Test func init_usesCardIDNameAndImageURL() {
        let imageURL = URL(string: "https://an-image.com/card.png")!
        let result = makeResult(card: Card(id: 7, name: "Roronoa Zoro", imageURL: imageURL))

        let sut = OnlineCardPresentation(result, locale: Locale(identifier: "en_US"))

        #expect(sut.id == 7)
        #expect(sut.name == "Roronoa Zoro")
        #expect(sut.imageURL == imageURL)
    }

    @Test func init_keepsCardToOpen() {
        let card = Card(id: 7, name: "Roronoa Zoro", number: "OP01-025", printing: "Foil")

        let sut = OnlineCardPresentation(makeResult(card: card), locale: Locale(identifier: "en_US"))

        #expect(sut.card == card)
    }

    @Test func init_usesNumberAndRarityAsDetails() {
        let result = makeResult(card: Card(id: 1, name: "a card", number: "OP01-001", rarity: "L"))

        let sut = OnlineCardPresentation(result, locale: Locale(identifier: "en_US"))

        #expect(sut.details == "OP01-001 · L")
    }

    @Test(arguments: [
        ("9.99", "USD", "$9.99"),
        ("1234.5", "USD", "$1,234.50"),
        ("9.99", "EUR", "€9.99"),
    ])
    func init_formatsPriceInItsCurrency(amount: String, currencyCode: String, expected: String) {
        let result = makeResult(price: Money(amount: Decimal(string: amount)!, currencyCode: currencyCode))

        let sut = OnlineCardPresentation(result, locale: Locale(identifier: "en_US"))

        #expect(sut.price == expected)
    }

    // The backend has no price yet for some cards, and they're still worth finding.
    @Test func init_saysNoPriceForCardWithoutPrice() {
        let result = makeResult(price: nil)

        let sut = OnlineCardPresentation(result, locale: Locale(identifier: "en_US"))

        #expect(sut.price == "No price")
    }

    // MARK: - Helpers
    private func makeResult(
        card: Card = Card(id: 1, name: "a card"),
        price: Money? = Money(amount: 1, currencyCode: "USD")
    ) -> CardSearchResult {
        CardSearchResult(
            card: card,
            price: price.map { PricePoint(cardID: card.id, date: Date(timeIntervalSince1970: 0), price: $0) }
        )
    }
}
