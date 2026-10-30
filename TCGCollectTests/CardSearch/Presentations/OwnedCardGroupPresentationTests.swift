//
//  OwnedCardGroupPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct OwnedCardGroupPresentationTests {

    @Test func init_usesCardIDNameAndImageURL() {
        let imageURL = URL(string: "https://an-image.com/card.png")!
        let group = OwnedCardGroup(card: Card(id: 7, name: "Roronoa Zoro", imageURL: imageURL), count: 1)

        let sut = OwnedCardGroupPresentation(group)

        #expect(sut.id == 7)
        #expect(sut.name == "Roronoa Zoro")
        #expect(sut.imageURL == imageURL)
    }

    @Test func init_keepsCardToOpen() {
        let card = Card(id: 7, name: "Roronoa Zoro", number: "OP01-025", printing: "Foil")

        let sut = OwnedCardGroupPresentation(OwnedCardGroup(card: card, count: 2))

        #expect(sut.card == card)
    }

    @Test func init_usesNumberAndRarityAsDetails() {
        let group = OwnedCardGroup(card: Card(id: 1, name: "a card", number: "OP01-001", rarity: "L"), count: 1)

        let sut = OwnedCardGroupPresentation(group)

        #expect(sut.details == "OP01-001 · L")
    }

    @Test(arguments: [(1, "×1"), (3, "×3"), (12, "×12")])
    func init_showsHowManyCopiesAreOwned(count: Int, expected: String) {
        let group = OwnedCardGroup(card: Card(id: 1, name: "a card"), count: count)

        let sut = OwnedCardGroupPresentation(group)

        #expect(sut.copies == expected)
    }
}
