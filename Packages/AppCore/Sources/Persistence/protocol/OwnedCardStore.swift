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
    func countCopies(of cardID: Card.ID) async throws -> Int
    /// Inserts all of `ownedCards` or, on failure, none of them. Each replaces any stored owned card
    /// with the same `id`, so saving an edited card updates it; new ones go after the stored ones, in order.
    func insert(_ ownedCards: [OwnedCard]) async throws
    /// Deletes all of `ownedCardIDs` or, on failure, none of them. IDs that aren't stored are ignored.
    func delete(ownedCardIDs: [OwnedCard.ID]) async throws
    func deleteNewestCopy(of cardID: Card.ID) async throws
}
