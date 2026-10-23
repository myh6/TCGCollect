//
//  OwnedCardSaver.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

public protocol OwnedCardSaver {
    /// Adds `ownedCard`, or updates it in place when one with the same `id` is already saved.
    func save(_ ownedCard: OwnedCard) async throws
}
