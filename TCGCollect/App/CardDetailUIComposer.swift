//
//  CardDetailUIComposer.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import AppCore

enum CardDetailUIComposer {
    struct Ownership {
        let copies: OwnedCopiesViewModel
        let addToCollection: AddToCollectionViewModel
    }

    static func makeOwnership(
        of cardID: Card.ID,
        in collection: OwnedCardCopyCounter & OwnedCardChangeObserver & OwnedCardSaver
    ) -> Ownership {
        Ownership(
            copies: OwnedCopiesViewModel(cardID: cardID, counter: collection, observer: collection),
            addToCollection: AddToCollectionViewModel(saver: collection)
        )
    }
}
