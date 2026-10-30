//
//  CardPriceViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class CardPriceViewModel {
    enum Range: CaseIterable {
        case month
        case threeMonths
        case all

        var days: Int? {
            switch self {
            case .month: 30
            case .threeMonths: 90
            case .all: nil
            }
        }
    }

    private(set) var range = Range.month
    private(set) var history = LoadingState<[PricePoint]>.idle

    private let cardID: Card.ID
    private let loader: CardPriceHistoryLoader
    private var latestRequest = 0

    init(cardID: Card.ID, loader: CardPriceHistoryLoader) {
        self.cardID = cardID
        self.loader = loader
    }

    func load() async {
        guard history == .idle || history == .failed else { return }
        await loadHistory()
    }

    func select(_ range: Range) async {
        guard range != self.range else { return }
        self.range = range
        await loadHistory()
    }

    private func loadHistory() async {
        latestRequest += 1
        let request = latestRequest
        history = .loading
        do {
            let points = try await loader.loadPriceHistory(for: [cardID], days: range.days)
            guard request == latestRequest else { return }
            history = .loaded(points.filter { $0.cardID == cardID }.sorted { $0.date < $1.date })
        } catch {
            guard request == latestRequest else { return }
            history = .failed
        }
    }
}
