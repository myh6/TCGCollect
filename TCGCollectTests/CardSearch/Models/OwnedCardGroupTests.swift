//
//  OwnedCardGroupTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct OwnedCardGroupTests {

    @Test func groups_deliversNothingForNoOwnedCards() {
        #expect(OwnedCardGroup.groups(from: []).isEmpty)
    }

    @Test func groups_deliversOneGroupOfOneForASingleCopy() {
        let luffy = makeCard(id: 1, name: "Monkey D. Luffy")

        let groups = OwnedCardGroup.groups(from: [OwnedCard(card: luffy)])

        #expect(groups == [OwnedCardGroup(card: luffy, count: 1)])
    }

    @Test func groups_countsCopiesOfTheSameCard() {
        let zoro = makeCard(id: 2, name: "Roronoa Zoro")

        let groups = OwnedCardGroup.groups(from: [OwnedCard(card: zoro), OwnedCard(card: zoro), OwnedCard(card: zoro)])

        #expect(groups == [OwnedCardGroup(card: zoro, count: 3)])
    }

    // Each card shows where its first copy was added, so a card doesn't jump when another copy is added.
    @Test func groups_ordersCardsByTheirFirstCopy() {
        let luffy = makeCard(id: 1, name: "Monkey D. Luffy")
        let zoro = makeCard(id: 2, name: "Roronoa Zoro")

        let groups = OwnedCardGroup.groups(from: [OwnedCard(card: luffy), OwnedCard(card: zoro), OwnedCard(card: luffy)])

        #expect(groups == [OwnedCardGroup(card: luffy, count: 2), OwnedCardGroup(card: zoro, count: 1)])
    }

    // Different printings of a card share a name but have their own card id, so they're counted apart.
    @Test func groups_keepsCardsWithTheSameNameButDifferentIDsApart() {
        let normal = makeCard(id: 1, name: "Roronoa Zoro")
        let parallel = makeCard(id: 2, name: "Roronoa Zoro")

        let groups = OwnedCardGroup.groups(from: [OwnedCard(card: normal), OwnedCard(card: parallel)])

        #expect(groups == [OwnedCardGroup(card: normal, count: 1), OwnedCardGroup(card: parallel, count: 1)])
    }

    @Test func id_isTheCardID() {
        #expect(OwnedCardGroup(card: makeCard(id: 7, name: "Nami"), count: 2).id == 7)
    }

    // MARK: - Helpers
    private func makeCard(id: Int, name: String) -> Card {
        Card(id: id, name: name)
    }
}
