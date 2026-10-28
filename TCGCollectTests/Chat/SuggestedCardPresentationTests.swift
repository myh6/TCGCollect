//
//  SuggestedCardPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct SuggestedCardPresentationTests {

    @Test func init_usesCardIDNameAndImageURL() {
        let imageURL = URL(string: "https://an-image.com/card.png")!
        let suggestion = makeSuggestion(card: Card(id: 7, name: "Roronoa Zoro", imageURL: imageURL))

        let sut = SuggestedCardPresentation(suggestion, locale: Locale(identifier: "en_US"))

        #expect(sut.id == 7)
        #expect(sut.name == "Roronoa Zoro")
        #expect(sut.imageURL == imageURL)
    }

    @Test(arguments: [
        ("OP01-001", "L", "OP01-001 · L"),
        ("OP01-001", nil, "OP01-001"),
        (nil, "L", "L"),
        (nil, nil, nil),
    ] as [(String?, String?, String?)])
    func init_joinsNumberAndRarityIntoDetails(number: String?, rarity: String?, expected: String?) {
        let suggestion = makeSuggestion(card: Card(id: 1, name: "a card", number: number, rarity: rarity))

        let sut = SuggestedCardPresentation(suggestion, locale: Locale(identifier: "en_US"))

        #expect(sut.details == expected)
    }

    @Test(arguments: [
        ("9.99", "USD", "$9.99"),
        ("1234.5", "USD", "$1,234.50"),
        ("9.99", "EUR", "€9.99"),
    ])
    func init_formatsPriceInItsCurrency(amount: String, currencyCode: String, expected: String) {
        let suggestion = makeSuggestion(amount: Decimal(string: amount)!, currencyCode: currencyCode)

        let sut = SuggestedCardPresentation(suggestion, locale: Locale(identifier: "en_US"))

        #expect(sut.price == expected)
    }

    // MARK: - Helpers
    private func makeSuggestion(
        card: Card = Card(id: 1, name: "a card"),
        amount: Decimal = 1,
        currencyCode: String = "USD"
    ) -> ChatAnswer.Suggestion {
        ChatAnswer.Suggestion(
            card: card,
            price: PricePoint(cardID: card.id, date: Date(timeIntervalSince1970: 0), price: Money(amount: amount, currencyCode: currencyCode))
        )
    }
}
