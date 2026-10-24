//
//  CollectionViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class CollectionViewModel {
    enum State: Equatable {
        case idle
        /// The first load, with nothing to show yet.
        case loading
        case loaded([OwnedCard])
        /// Loading again while still showing these cards.
        case reloading([OwnedCard])
        case failed
    }

    private(set) var state = State.idle

    private let loader: OwnedCardLoader

    init(loader: OwnedCardLoader) {
        self.loader = loader
    }

    /// Loads the collection, e.g. each time the screen appears. Does nothing while already loading.
    /// A reload keeps showing the current cards, and keeps them if it fails: slightly out-of-date cards are more useful than an error.
    func load() async {
        switch state {
        case .loading, .reloading:
            return
        case let .loaded(ownedCards):
            state = .reloading(ownedCards)
            state = .loaded((try? await loader.load()) ?? ownedCards)
        case .idle, .failed:
            state = .loading
            do {
                state = .loaded(try await loader.load())
            } catch {
                state = .failed
            }
        }
    }
}
