//
//  CardSetsView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import SwiftUI
import AppCore

struct CardSetsScreen: View {
    let game: CardGame
    @State private var viewModel: CatalogListViewModel<CardSet>

    init(game: CardGame, loader: CardSetsLoader) {
        self.game = game
        _viewModel = State(initialValue: CatalogUIComposer.makeSetsList(of: game, loader: loader))
    }

    var body: some View {
        CardSetsView(title: game.name, viewModel: viewModel)
    }
}

struct CardSetsView: View {
    let title: String
    let viewModel: CatalogListViewModel<CardSet>

    var body: some View {
        CatalogContent(state: viewModel.items, failureTitle: "Couldn't Load the Sets", retry: viewModel.load) { sets in
            if sets.isEmpty {
                ContentUnavailableView("No Sets Yet", systemImage: "square.stack.3d.up")
            } else {
                List(sets.map { CardSetPresentation($0) }) { set in
                    NavigationLink(value: set.set) {
                        CardSetRow(set: set)
                    }
                }
            }
        }
        .navigationTitle(title)
        .task { await viewModel.load() }
    }
}

struct CardSetRow: View {
    let set: CardSetPresentation

    private static var iconSize: CGSize { CGSize(width: 72, height: 48) }

    var body: some View {
        HStack(spacing: 12) {
            CardImageView(url: set.iconURL)
                .frame(width: Self.iconSize.width, height: Self.iconSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(set.name)
                Text(set.details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
@MainActor
private func previewCardSetsView(_ load: @escaping () async throws -> [CardSet]) -> some View {
    NavigationStack {
        CardSetsView(title: "One Piece Card Game", viewModel: CatalogListViewModel(load: load))
    }
}

#Preview("Sets") {
    previewCardSetsView {
        [
            CardSet(id: 3, name: "Starter Deck 21: EX - Gear 5", cardCount: 17, releaseDate: .now, iconURL: nil),
            CardSet(id: 2, name: "Paramount War", cardCount: 121, releaseDate: .now.addingTimeInterval(-86_400 * 600), iconURL: nil),
            CardSet(id: 1, name: "Romance Dawn", cardCount: 156, releaseDate: nil, iconURL: nil),
        ]
    }
}

#Preview("Empty") {
    previewCardSetsView { [] }
}

#Preview("Failed") {
    previewCardSetsView { throw CancellationError() }
}
#endif
