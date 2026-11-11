//
//  ManagedOwnedCard.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import SwiftData
import Domain

/// How SwiftData stores an `OwnedCard`. Internal, so nothing outside Persistence depends on SwiftData.
/// No `.unique` attributes, since CloudKit sync doesn't support them; the store keeps ids unique itself.
@Model
final class ManagedOwnedCard {
    var ownedCardID: UUID
    /// Where the card comes in the collection, so cards are delivered in the order they were added.
    var position: Int

    // A snapshot of the card when it was added, so the collection shows it without the network.
    var cardID: Int
    var name: String
    var number: String?
    var setID: Int?
    var setName: String?
    var imageURL: URL?
    var rarity: String?
    var printing: String?

    var purchaseAmount: Decimal?
    var purchaseCurrencyCode: String?
    var acquiredOn: Date?

    init(_ ownedCard: OwnedCard, position: Int) {
        ownedCardID = ownedCard.id
        self.position = position
        cardID = ownedCard.card.id
        name = ownedCard.card.name
        update(from: ownedCard)
    }

    /// Takes the values of an edited card. Its id and position stay, so it keeps its place in the collection.
    func update(from ownedCard: OwnedCard) {
        cardID = ownedCard.card.id
        name = ownedCard.card.name
        number = ownedCard.card.number
        setID = ownedCard.card.setID
        setName = ownedCard.card.setName
        imageURL = ownedCard.card.imageURL
        rarity = ownedCard.card.rarity
        printing = ownedCard.card.printing
        purchaseAmount = ownedCard.purchasePrice?.amount
        purchaseCurrencyCode = ownedCard.purchasePrice?.currencyCode
        acquiredOn = ownedCard.acquiredOn
    }

    var ownedCard: OwnedCard {
        OwnedCard(
            id: ownedCardID,
            card: Card(
                id: cardID,
                name: name,
                number: number,
                setID: setID,
                setName: setName,
                imageURL: imageURL,
                rarity: rarity,
                printing: printing
            ),
            purchasePrice: purchasePrice,
            acquiredOn: acquiredOn
        )
    }

    private var purchasePrice: Money? {
        guard let purchaseAmount, let purchaseCurrencyCode else { return nil }
        return Money(amount: purchaseAmount, currencyCode: purchaseCurrencyCode)
    }
}
