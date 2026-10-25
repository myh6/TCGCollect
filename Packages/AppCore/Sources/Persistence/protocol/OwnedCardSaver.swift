//
//  OwnedCardSaver.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

public protocol OwnedCardSaver {
    /// Saves all of `ownedCards` or, on failure, none of them, so adding several copies can't stop halfway.
    /// Each adds a card, or updates it in place when one with the same `id` is already saved.
    func save(_ ownedCards: [OwnedCard]) async throws
}
