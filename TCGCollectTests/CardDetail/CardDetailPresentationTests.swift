//
//  CardDetailPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import Foundation
import Testing
import AppCore
import HoloCard
@testable import TCGCollect

struct CardDetailPresentationTests {

    @Test func init_usesCardIDNameSetNameAndImageURL() {
        let imageURL = URL(string: "https://an-image.com/card.png")!
        let card = Card(id: 7, name: "Roronoa Zoro", setName: "Romance Dawn", imageURL: imageURL)

        let sut = CardDetailPresentation(card)

        #expect(sut.id == 7)
        #expect(sut.name == "Roronoa Zoro")
        #expect(sut.setName == "Romance Dawn")
        #expect(sut.imageURL == imageURL)
    }

    @Test func init_usesNumberAndRarityAsDetails() {
        let sut = CardDetailPresentation(Card(id: 1, name: "a card", number: "OP01-001", rarity: "L"))

        #expect(sut.details == "OP01-001 · L")
    }

    @Test(arguments: ["Foil", "Normal", nil])
    func init_usesCardPrinting(printing: String?) {
        let sut = CardDetailPresentation(Card(id: 1, name: "a card", printing: printing))

        #expect(sut.printing == printing)
    }

    @Test(arguments: [("Foil", HoloStyle.foil), ("Normal", .plain)])
    func init_usesCardHoloStyle(printing: String, expected: HoloStyle) {
        let sut = CardDetailPresentation(Card(id: 1, name: "a card", printing: printing))

        #expect(sut.holoStyle == expected)
    }
}
