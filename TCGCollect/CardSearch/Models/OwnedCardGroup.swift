//
//  OwnedCardGroup.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import AppCore

/// One card the user owns, with how many copies they have, e.g. "Roronoa Zoro ×3".
nonisolated struct OwnedCardGroup: Identifiable, Equatable {
    let card: Card
    let count: Int

    var id: Card.ID { card.id }

    /// Groups copies by card id, in the order each card's first copy appears.
    static func groups(from ownedCards: [OwnedCard]) -> [OwnedCardGroup] {
        var order = [Card.ID]()
        var groups = [Card.ID: OwnedCardGroup]()
        for ownedCard in ownedCards {
            let card = ownedCard.card
            if let group = groups[card.id] {
                groups[card.id] = OwnedCardGroup(card: group.card, count: group.count + 1)
            } else {
                order.append(card.id)
                groups[card.id] = OwnedCardGroup(card: card, count: 1)
            }
        }
        return order.compactMap { groups[$0] }
    }
}
