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

    static func makeOwnership(of cardID: Card.ID, in collection: OwnedCardLoader & OwnedCardSaver) -> Ownership {
        let copies = OwnedCopiesViewModel(cardID: cardID, loader: collection)
        let saverThenRecount = OwnedCardSaverAfterSaveDecorator(decoratee: collection, afterSave: { await copies.refresh() })
        return Ownership(copies: copies, addToCollection: AddToCollectionViewModel(saver: saverThenRecount))
    }
}
