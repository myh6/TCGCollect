//
//  CollectionValueViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class CollectionValueViewModel {
    enum Range: CaseIterable {
        case week
        case month
        case threeMonths

        var days: Int {
            switch self {
            case .week: 7
            case .month: 30
            case .threeMonths: 90
            }
        }
    }

    private(set) var range = Range.month
    private(set) var valueHistory = LoadingState<CollectionValueHistory>.idle
    private(set) var isReloading = false

    private var ownedCards = [OwnedCard]()
    private let loader: CollectionValueHistoryLoader
    private var latestRequest = 0

    init(loader: CollectionValueHistoryLoader) {
        self.loader = loader
    }

    func load(_ ownedCards: [OwnedCard]) async {
        guard ownedCards != self.ownedCards || valueHistory == .idle || valueHistory == .failed else { return }
        self.ownedCards = ownedCards
        await loadValueHistory()
    }

    func select(_ range: Range) async {
        guard range != self.range else { return }
        self.range = range
        await loadValueHistory()
    }

    private func loadValueHistory() async {
        latestRequest += 1
        let request = latestRequest
        let quantities = Dictionary(grouping: ownedCards, by: \.card.id).mapValues(\.count)
        guard !quantities.isEmpty else {
            valueHistory = .loaded(CollectionValueHistory(currentTotal: nil, points: []))
            return
        }
        if case .loaded = valueHistory {
            isReloading = true
        } else {
            valueHistory = .loading
        }
        do {
            let history = try await loader.loadValueHistory(of: quantities, days: range.days)
            guard request == latestRequest else { return }
            valueHistory = .loaded(history)
        } catch {
            guard request == latestRequest else { return }
            valueHistory = .failed
        }
        isReloading = false
    }
}
