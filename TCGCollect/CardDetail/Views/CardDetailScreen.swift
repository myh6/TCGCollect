//
//  CardDetailScreen.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI
import AppCore

struct CardDetailScreen: View {
    @State private var viewModel: CardDetailViewModel
    @State private var priceViewModel: CardPriceViewModel
    @State private var ownership: CardDetailUIComposer.Ownership?

    init(
        card: Card,
        loader: CardDetailsLoader,
        priceHistoryLoader: CardPriceHistoryLoader,
        ownership: CardDetailUIComposer.Ownership?
    ) {
        _viewModel = State(initialValue: CardDetailViewModel(card: card, loader: loader))
        _priceViewModel = State(initialValue: CardPriceViewModel(cardID: card.id, loader: priceHistoryLoader))
        _ownership = State(initialValue: ownership)
    }

    var body: some View {
        CardDetailView(viewModel: viewModel, priceViewModel: priceViewModel, ownership: ownership)
    }
}
