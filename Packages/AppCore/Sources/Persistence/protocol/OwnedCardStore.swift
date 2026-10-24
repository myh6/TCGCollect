//
//  OwnedCardStore.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

/// Where owned cards are kept. Implementations hide their storage, e.g. SwiftData, behind Domain types.
public protocol OwnedCardStore {
    func retrieveAll() async throws -> [OwnedCard]
    /// Inserts all of `ownedCards` or, on failure, none of them. Each replaces any stored owned card
    /// with the same `id`, so saving an edited card updates it; new ones go after the stored ones, in order.
    func insert(_ ownedCards: [OwnedCard]) async throws
    /// Does nothing when no owned card has `ownedCardID`: either way, it's no longer stored.
    func delete(ownedCardID: OwnedCard.ID) async throws
}
