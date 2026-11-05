//
//  CardSetView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import SwiftUI
import AppCore

struct CardSetScreen: View {
    @State private var viewModel: CardSetViewModel

    init(set: CardSet, loader: CardSetPageLoader) {
        _viewModel = State(initialValue: CardSetViewModel(set: set, loader: loader))
    }

    var body: some View {
        CardSetView(viewModel: viewModel)
    }
}

struct CardSetView: View {
    let viewModel: CardSetViewModel

    // As many columns as fit, each at least as wide as a tile.
    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12, alignment: .top)]

    var body: some View {
        CatalogContent(state: viewModel.cards, failureTitle: "Couldn't Load the Cards", retry: viewModel.loadFirstPage) { results in
            if results.isEmpty {
                ContentUnavailableView("No Cards Yet", systemImage: "rectangle.stack")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(results.map { OnlineCardPresentation($0) }) { card in
                            NavigationLink(value: card.card) {
                                CardTile(name: card.name, details: card.details, imageURL: card.imageURL) {
                                    Text(card.price)
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    moreCards(after: results.count)
                }
                .contentMargins(16, for: .scrollContent)
            }
        }
        .navigationTitle(viewModel.set.name)
        .task { await viewModel.loadFirstPage() }
    }

    @ViewBuilder
    private func moreCards(after count: Int) -> some View {
        if viewModel.hasMore {
            Group {
                switch viewModel.more {
                case .idle, .loading:
                    ProgressView()
                        // Again after each page, in case the end of the grid is still on screen.
                        .task(id: count) { await viewModel.loadMore() }
                case .failed:
                    VStack(spacing: 8) {
                        Text("Couldn't load more cards.")
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }
}

#if DEBUG
private nonisolated struct PreviewPageLoader: CardSetPageLoader {
    let totalCount: Int

    func loadCards(inSet setID: CardSet.ID, offset: Int) async throws -> CardSetPage {
        try await Task.sleep(for: .seconds(1))
        let ids = offset..<min(offset + 12, totalCount)
        let cards = ids.map { id in
            CardSearchResult(
                card: Card(id: id, name: "Card \(id + 1)", number: String(format: "OP01-%03d", id + 1), rarity: "C"),
                price: id.isMultiple(of: 3) ? nil : PricePoint(cardID: id, date: .now, price: Money(amount: Decimal(id) + 0.99, currencyCode: "USD"))
            )
        }
        return CardSetPage(cards: cards, totalCount: totalCount)
    }
}

#Preview("Cards") {
    NavigationStack {
        CardSetScreen(set: CardSet(id: 1, name: "Romance Dawn", cardCount: 40, releaseDate: nil, iconURL: nil), loader: PreviewPageLoader(totalCount: 40))
    }
}

#Preview("Empty") {
    NavigationStack {
        CardSetScreen(set: CardSet(id: 1, name: "Romance Dawn", cardCount: 0, releaseDate: nil, iconURL: nil), loader: PreviewPageLoader(totalCount: 0))
    }
}
#endif
