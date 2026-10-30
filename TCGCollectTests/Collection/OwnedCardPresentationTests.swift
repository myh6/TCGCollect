//
//  OwnedCardPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct OwnedCardPresentationTests {

    @Test func init_usesCardNameAndImageURL() {
        let imageURL = URL(string: "https://an-image.com/card.png")!
        let ownedCard = OwnedCard(card: Card(id: 7, name: "Roronoa Zoro", imageURL: imageURL))

        let sut = OwnedCardPresentation(ownedCard)

        #expect(sut.name == "Roronoa Zoro")
        #expect(sut.imageURL == imageURL)
    }

    @Test func init_keepsCardToOpen() {
        let card = Card(id: 7, name: "Roronoa Zoro", number: "OP01-025", printing: "Foil")

        let sut = OwnedCardPresentation(OwnedCard(card: card))

        #expect(sut.card == card)
    }

    // Two copies of the same card are two tiles, so each needs its own id.
    @Test func init_usesOwnedCardIDNotCardID() {
        let card = Card(id: 7, name: "Roronoa Zoro")
        let firstCopy = OwnedCard(card: card)
        let secondCopy = OwnedCard(card: card)

        #expect(OwnedCardPresentation(firstCopy).id == firstCopy.id)
        #expect(OwnedCardPresentation(secondCopy).id == secondCopy.id)
        #expect(OwnedCardPresentation(firstCopy).id != OwnedCardPresentation(secondCopy).id)
    }

    @Test(arguments: [
        ("OP01-001", "L", "OP01-001 · L"),
        ("OP01-001", nil, "OP01-001"),
        (nil, "L", "L"),
        (nil, nil, nil),
    ] as [(String?, String?, String?)])
    func init_joinsNumberAndRarityIntoDetails(number: String?, rarity: String?, expected: String?) {
        let ownedCard = OwnedCard(card: Card(id: 1, name: "a card", number: number, rarity: rarity))

        let sut = OwnedCardPresentation(ownedCard)

        #expect(sut.details == expected)
    }
}
