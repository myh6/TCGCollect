//
//  CatalogView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import SwiftUI
import AppCore

struct CatalogView: View {
    let viewModel: CatalogListViewModel<CardGame>
    let setsLoader: CardSetsLoader
    let setPageLoader: CardSetPageLoader

    var body: some View {
        CatalogContent(state: viewModel.items, failureTitle: "Couldn't Load the Catalog", retry: viewModel.load) { games in
            if games.isEmpty {
                ContentUnavailableView(
                    "No Games Yet",
                    systemImage: "books.vertical",
                    description: Text("Games show up here once their cards are available.")
                )
            } else {
                List(games, id: \.slug) { game in
                    NavigationLink(game.name, value: game)
                }
            }
        }
        .navigationTitle("Catalog")
        .navigationDestination(for: CardGame.self) { game in
            CardSetsScreen(game: game, loader: setsLoader)
        }
        .navigationDestination(for: CardSet.self) { set in
            CardSetScreen(set: set, loader: setPageLoader)
        }
        .task { await viewModel.load() }
    }
}

struct CatalogUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Catalog unavailable",
            systemImage: "books.vertical",
            description: Text("The catalog needs a connection to the card server.")
        )
        .navigationTitle("Catalog")
    }
}

#if DEBUG
private nonisolated struct PreviewCatalogLoader: CardSetsLoader, CardSetPageLoader {
    func loadSets(ofGame gameSlug: String) async throws -> [CardSet] {
        [CardSet(id: 1, name: "Romance Dawn", cardCount: 156, releaseDate: .now)]
    }

    func loadCards(inSet setID: CardSet.ID, offset: Int) async throws -> CardSetPage {
        CardSetPage(cards: [], totalCount: 0)
    }
}

@MainActor
private func previewCatalogView(_ load: @escaping () async throws -> [CardGame]) -> some View {
    NavigationStack {
        CatalogView(viewModel: CatalogListViewModel(load: load), setsLoader: PreviewCatalogLoader(), setPageLoader: PreviewCatalogLoader())
    }
}

#Preview("Games") {
    previewCatalogView { [CardGame(slug: "one-piece-card-game", name: "One Piece Card Game")] }
}

#Preview("Empty") {
    previewCatalogView { [] }
}

#Preview("Loading") {
    previewCatalogView {
        try await Task.sleep(for: .seconds(3600))
        return []
    }
}

#Preview("Failed") {
    previewCatalogView { throw CancellationError() }
}

#Preview("Unavailable") {
    NavigationStack {
        CatalogUnavailableView()
    }
}
#endif
