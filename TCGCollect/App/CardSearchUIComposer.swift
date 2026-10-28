//
//  CardSearchUIComposer.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import AppCore

/// Builds the sections of the card search screen, one per searcher.
/// Separate, since the collection and the backend can each be unavailable on their own.
enum CardSearchUIComposer {
    /// Shows each card the user owns once, with how many copies they have.
    static func makeOwnedCardsSection(searching searcher: OwnedCardSearcher) -> SearchSectionViewModel<OwnedCardGroup> {
        SearchSectionViewModel { query in
            OwnedCardGroup.groups(from: try await searcher.search(query))
        }
    }

    static func makeOnlineCardsSection(searching searcher: CardSearcher) -> SearchSectionViewModel<CardSearchResult> {
        SearchSectionViewModel { query in
            try await searcher.search(query)
        }
    }
}
