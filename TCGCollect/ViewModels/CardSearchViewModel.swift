//
//  CardSearchViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Observation
import AppCore

/// Searches the cards the user owns and the cards online, in two sections that update on their own.
/// The view waits for a pause in typing before calling `search(_:)`.
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
    private(set) var onlineCards = SectionState<CardSearchResult>.idle

    private let ownedCardSearcher: OwnedCardSearcher
    private let cardSearcher: CardSearcher

    init(ownedCardSearcher: OwnedCardSearcher, cardSearcher: CardSearcher) {
        self.ownedCardSearcher = ownedCardSearcher
        self.cardSearcher = cardSearcher
    }

    func search(_ query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= Self.minimumQueryLength else {
            ownedCards = .idle
            onlineCards = .idle
            return
        }

        // Together, so the quick local search shows its cards without waiting for the network.
        async let owned: Void = update(\.ownedCards) {
            OwnedCardGroup.groups(from: try await self.ownedCardSearcher.search(query))
        }
        async let online: Void = update(\.onlineCards) {
            try await self.cardSearcher.search(query)
        }
        _ = await (owned, online)
    }

    private func update<Item>(
        _ section: ReferenceWritableKeyPath<CardSearchViewModel, SectionState<Item>>,
        with search: @MainActor () async throws -> [Item]
    ) async {
        self[keyPath: section] = .searching(previous: self[keyPath: section].items)
        do {
            self[keyPath: section] = .loaded(try await search())
        } catch {
            self[keyPath: section] = .failed
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
