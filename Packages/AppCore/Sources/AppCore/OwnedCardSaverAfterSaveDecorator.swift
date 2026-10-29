//
//  OwnedCardSaverAfterSaveDecorator.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Domain
import Persistence

public struct OwnedCardSaverAfterSaveDecorator: OwnedCardSaver {
    private let decoratee: OwnedCardSaver
    private let afterSave: () async -> Void

    public init(decoratee: OwnedCardSaver, afterSave: @escaping () async -> Void) {
        self.decoratee = decoratee
        self.afterSave = afterSave
    }

    public func save(_ ownedCards: [OwnedCard]) async throws {
        try await decoratee.save(ownedCards)
        await afterSave()
    }
}
