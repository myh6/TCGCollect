//
//  CardSetViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class CardSetViewModel {
    enum MoreStatus: Equatable {
        case idle
        case loading
        case failed
    }

    let set: CardSet
    private(set) var cards = LoadingState<[CardSearchResult]>.idle
    private(set) var more = MoreStatus.idle
    private(set) var hasMore = false

    private let loader: CardSetPageLoader

    init(set: CardSet, loader: CardSetPageLoader) {
        self.set = set
        self.loader = loader
    }

    func loadFirstPage() async {
        guard cards == .idle || cards == .failed else { return }
        cards = .loading
        do {
            let page = try await loader.loadCards(inSet: set.id, offset: 0)
            show(page.cards, of: page)
        } catch {
            cards = .failed
        }
    }

    func loadMore() async {
        guard case let .loaded(shown) = cards, hasMore, more != .loading else { return }
        more = .loading
        do {
            let page = try await loader.loadCards(inSet: set.id, offset: shown.count)
            let shownIDs = Set(shown.map(\.card.id))
            show(shown + page.cards.filter { !shownIDs.contains($0.card.id) }, of: page)
            more = .idle
        } catch {
            more = .failed
        }
    }

    private func show(_ shown: [CardSearchResult], of page: CardSetPage) {
        cards = .loaded(shown)
        hasMore = !page.cards.isEmpty && shown.count < page.totalCount
    }
}
