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
    /// Replaces any stored owned card with the same `id`, so saving an edited card updates it.
    func insert(_ ownedCard: OwnedCard) async throws
    /// Does nothing when no owned card has `ownedCardID`: either way, it's no longer stored.
    func delete(ownedCardID: OwnedCard.ID) async throws
}
