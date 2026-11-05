//
//  OwnedCopiesViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class OwnedCopiesViewModel {
    private(set) var copies = LoadingState<Int>.idle

    private let cardID: Card.ID
    private let counter: OwnedCardCopyCounter
    private let observer: OwnedCardChangeObserver

    init(cardID: Card.ID, counter: OwnedCardCopyCounter, observer: OwnedCardChangeObserver) {
        self.cardID = cardID
        self.counter = counter
        self.observer = observer
    }

    func start() async {
        let changes = observer.changes()
        await load()
        for await _ in changes {
            await refresh()
        }
    }

    func load() async {
        guard copies == .idle || copies == .failed else { return }
        copies = .loading
        do {
            copies = .loaded(try await count())
        } catch {
            copies = .failed
        }
    }

    func refresh() async {
        guard case let .loaded(current) = copies else {
            await load()
            return
        }
        copies = .loaded((try? await count()) ?? current)
    }

    private func count() async throws -> Int {
        try await counter.countCopies(of: cardID)
    }
}
