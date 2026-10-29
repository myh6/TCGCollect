//
//  CardDetailViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class CardDetailViewModel {
    enum DetailsState: Equatable {
        case idle
        case loading
        case loaded(GameDetails?)
        case failed
    }

    let card: CardDetailPresentation
    private(set) var details = DetailsState.idle

    private let cardID: Card.ID
    private let loader: CardDetailsLoader

    init(card: Card, loader: CardDetailsLoader) {
        self.card = CardDetailPresentation(card)
        self.cardID = card.id
        self.loader = loader
    }

    func loadDetails() async {
        guard details == .idle || details == .failed else { return }
        details = .loading
        do {
            details = .loaded(try await loader.loadDetails(for: cardID))
        } catch {
            details = .failed
        }
    }
}
