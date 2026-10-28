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

    /// How many copies can be added at once. Kept to one digit for the tile's layout, not a limit on how many
    /// copies someone owns: adding the card again from another suggestion adds more.
    static let copiesRange = 1...9

    private var statuses = [Card.ID: Status]()
    private var copies = [Card.ID: Int]()

    private let saver: OwnedCardSaver

    init(saver: OwnedCardSaver) {
        self.saver = saver
    }

    func status(for cardID: Card.ID) -> Status {
        statuses[cardID, default: .notAdded]
    }

    func copies(for cardID: Card.ID) -> Int {
        copies[cardID, default: Self.copiesRange.lowerBound]
    }

    func incrementCopies(for cardID: Card.ID) {
        setCopies(copies(for: cardID) + 1, for: cardID)
    }

    func decrementCopies(for cardID: Card.ID) {
        setCopies(copies(for: cardID) - 1, for: cardID)
    }

    /// Does nothing while the card is being added or once it's added, so the count shown stays the one saved.
    private func setCopies(_ count: Int, for cardID: Card.ID) {
        guard status(for: cardID) != .adding, status(for: cardID) != .added else { return }
        copies[cardID] = min(max(count, Self.copiesRange.lowerBound), Self.copiesRange.upperBound)
    }

    /// Saves the chosen number of copies in one save, so either all of them are added or none.
    /// Does nothing while the card is being added or once it's added, so a second tap can't add them twice.
    func add(_ card: Card) async {
        guard status(for: card.id) != .adding, status(for: card.id) != .added else { return }

        statuses[card.id] = .adding
        do {
            // Each copy is its own owned card, with its own id, so it can be edited or removed on its own.
            try await saver.save((0..<copies(for: card.id)).map { _ in OwnedCard(card: card) })
            statuses[card.id] = .added
        } catch {
            statuses[card.id] = .failed
        }
    }
}
