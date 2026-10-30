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

    init(card: Card, loader: CardDetailsLoader) {
        _viewModel = State(initialValue: CardDetailViewModel(card: card, loader: loader))
    }

    var body: some View {
        CardDetailView(viewModel: viewModel)
    }
}
