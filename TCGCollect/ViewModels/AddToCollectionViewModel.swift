//
//  AddToCollectionViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import Foundation
import Observation
import AppCore

/// Adds cards to the collection and remembers, for each card, how adding it went.
@MainActor
@Observable
final class AddToCollectionViewModel {
    enum Status: Equatable {
        case notAdded
        case adding
        case added
        case failed
    }

    private var statuses = [Card.ID: Status]()

    private let saver: OwnedCardSaver

    init(saver: OwnedCardSaver) {
        self.saver = saver
    }

    func status(for cardID: Card.ID) -> Status {
        statuses[cardID, default: .notAdded]
    }

    /// Does nothing while the card is being added or once it's added, so a second tap can't add a second copy.
    func add(_ card: Card) async {
        guard status(for: card.id) != .adding, status(for: card.id) != .added else { return }

        statuses[card.id] = .adding
        do {
            try await saver.save(OwnedCard(card: card))
            statuses[card.id] = .added
        } catch {
            statuses[card.id] = .failed
        }
    }
}
