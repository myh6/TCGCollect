//
//  CardSearchViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Observation
import AppCore

/// Searches the cards the user owns. The view waits for a pause in typing before calling `search(_:)`.
@MainActor
@Observable
final class CardSearchViewModel {
    enum SectionState<Item: Equatable>: Equatable {
        case idle
        /// Searching while still showing the results of the search before, if any.
        case searching(previous: [Item])
        case loaded([Item])
        case failed
    }

    /// One letter matches too many cards to be useful.
    static let minimumQueryLength = 2

    private(set) var ownedCards = SectionState<OwnedCardGroup>.idle

    private let ownedCardSearcher: OwnedCardSearcher

    init(ownedCardSearcher: OwnedCardSearcher) {
        self.ownedCardSearcher = ownedCardSearcher
    }

    func search(_ query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= Self.minimumQueryLength else {
            ownedCards = .idle
            return
        }

        ownedCards = .searching(previous: ownedCards.items)
        do {
            ownedCards = .loaded(OwnedCardGroup.groups(from: try await ownedCardSearcher.search(query)))
        } catch {
            ownedCards = .failed
        }
    }
}

private extension CardSearchViewModel.SectionState {
    var items: [Item] {
        switch self {
        case let .searching(items), let .loaded(items): items
        case .idle, .failed: []
        }
    }
}
