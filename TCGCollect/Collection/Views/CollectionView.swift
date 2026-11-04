//
//  CollectionView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import SwiftUI
import AppCore

struct CollectionView: View {
    let viewModel: CollectionViewModel
    let valueViewModel: CollectionValueViewModel?

    var body: some View {
        content
            .navigationTitle("Collection")
            // Each time the tab appears, so cards added in chat show up.
            .task { await viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case let .loaded(ownedCards), let .reloading(ownedCards):
            if ownedCards.isEmpty {
                ContentUnavailableView(
                    "No Cards Yet",
                    systemImage: "rectangle.stack",
                    description: Text("Cards you add from Chat show up here.")
                )
            } else {
                OwnedCardsGrid(cards: ownedCards.map(OwnedCardPresentation.init)) {
                    if let valueViewModel {
                        CollectionValueSection(viewModel: valueViewModel, ownedCards: ownedCards)
                    }
                }
            }
        case .failed:
            ContentUnavailableView(
                "Couldn't Load Your Collection",
                systemImage: "exclamationmark.triangle",
                description: Text("Please try again later.")
            )
        }
    }
}

struct OwnedCardsGrid<Header: View>: View {
    let cards: [OwnedCardPresentation]
    @ViewBuilder let header: Header

    // As many columns as fit, each at least as wide as a tile.
    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12, alignment: .top)]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(cards) { card in
                        NavigationLink(value: card.card) {
                            OwnedCardTile(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
}

struct OwnedCardTile: View {
    let card: OwnedCardPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardImageView(url: card.imageURL)
                // A trading card's 63 × 88 mm shape, filling the column's width.
                .aspectRatio(63.0 / 88.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(card.name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
            if let details = card.details {
                Text(details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct CollectionUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Collection unavailable",
            systemImage: "rectangle.stack.badge.minus",
            description: Text("Your collection couldn't be opened on this device.")
        )
        .navigationTitle("Collection")
    }
}

#if DEBUG
/// Answers previews with a fixed result, or never answers when `result` is nil.
private nonisolated struct PreviewLoader: OwnedCardLoader, OwnedCardChangeObserver {
    let result: Result<[OwnedCard], Error>?

    func load() async throws -> [OwnedCard] {
        guard let result else {
            try await Task.sleep(for: .seconds(3600))
            throw CancellationError()
        }
        return try result.get()
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { _ in }
    }
}

private nonisolated struct PreviewValueLoader: CollectionValueHistoryLoader {
    func loadValueHistory(of quantities: [Card.ID: Int], days: Int?) async throws -> CollectionValueHistory {
        let values: [Decimal] = [118.4, 121.0, 119.75, 124.3, 126.1, 125.5, 129.8]
        let points = values.enumerated().map { index, value in
            CollectionValuePoint(date: .now.addingTimeInterval(TimeInterval(index - values.count + 1) * 86_400), value: Money(amount: value, currencyCode: "USD"))
        }
        return CollectionValueHistory(currentTotal: points.last?.value, points: points)
    }
}

@MainActor
private func previewCollectionViewModel(_ result: Result<[OwnedCard], Error>?) -> CollectionViewModel {
    let collection = PreviewLoader(result: result)
    return CollectionViewModel(loader: collection, observer: collection)
}

/// Dummy cards, with and without number, rarity and image, to see every kind of tile.
private let previewOwnedCards = [
    Card(id: 1, name: "Monkey.D.Luffy", number: "OP01-024", rarity: "L"),
    Card(id: 2, name: "Roronoa Zoro", number: "OP01-025", rarity: "SR"),
    Card(id: 3, name: "Nami", number: "OP01-016", rarity: "R"),
    Card(id: 4, name: "Trafalgar Law, a card with a long name", number: "OP01-047", rarity: "SR"),
    Card(id: 5, name: "Sanji"),
    Card(id: 2, name: "Roronoa Zoro", number: "OP01-025", rarity: "SR"),
].map { OwnedCard(card: $0) }

#Preview("Cards") {
    NavigationStack {
        CollectionView(
            viewModel: previewCollectionViewModel(.success(previewOwnedCards)),
            valueViewModel: CollectionValueViewModel(loader: PreviewValueLoader())
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        CollectionView(viewModel: previewCollectionViewModel(.success([])), valueViewModel: nil)
    }
}

#Preview("Loading") {
    NavigationStack {
        CollectionView(viewModel: previewCollectionViewModel(nil), valueViewModel: nil)
    }
}

#Preview("Failed") {
    NavigationStack {
        CollectionView(viewModel: previewCollectionViewModel(.failure(CancellationError())), valueViewModel: nil)
    }
}
#endif
