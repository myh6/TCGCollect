//
//  SearchSectionViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Observation

/// One section of search results, e.g. the cards the user owns. The view waits for a pause in typing before calling `search(_:)`.
@MainActor
@Observable
final class SearchSectionViewModel<Item: Equatable> {
    enum State: Equatable {
        case idle
        /// Searching while still showing the results of the search before, if any.
        case searching(previous: [Item])
        case loaded([Item])
        case failed
    }

    /// One letter matches too many cards to be useful.
    static var minimumQueryLength: Int { 2 }

    private(set) var state = State.idle

    private let searchItems: (String) async throws -> [Item]

    init(search: @escaping (String) async throws -> [Item]) {
        self.searchItems = search
    }

    func search(_ query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= Self.minimumQueryLength else {
            state = .idle
            return
        }

        state = .searching(previous: state.items)
        do {
            state = .loaded(try await searchItems(query))
        } catch {
            state = .failed
        }
    }
}

private extension SearchSectionViewModel.State {
    var items: [Item] {
        switch self {
        case let .searching(items), let .loaded(items): items
        case .idle, .failed: []
        }
    }
}
