//
//  CardSearchView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import SwiftUI
import AppCore

/// Searches the cards the user owns and the cards online as they type, in two sections.
struct CardSearchView: View {
    /// nil when the collection can't be opened, so only online cards are searched.
    let ownedCards: SearchSectionViewModel<OwnedCardGroup>?
    /// nil when the backend isn't configured, so only owned cards are searched.
    let onlineCards: SearchSectionViewModel<CardSearchResult>?
    /// Makes what adds online cards to the collection, or nil to show no add buttons, e.g. without a collection.
    var makeAddToCollection: (() -> AddToCollectionViewModel)?
    @State var query = ""
    // A fresh one each time the tab appears, so a card added on an earlier visit can be added again.
    @State private var addToCollection: AddToCollectionViewModel?
    @AppStorage("searchScope") private var scope = SearchScope.all

    var body: some View {
        List {
            if scope.showsOwned, let ownedCards, ownedCards.state != .idle {
                Section {
                    SearchResults(state: ownedCards.state, noResultsMessage: "None of your cards match.") { groups in
                        ForEach(groups.map(OwnedCardGroupPresentation.init)) { OwnedCardGroupRow(card: $0) }
                    }
                } header: {
                    SearchSectionHeader(title: "Cards you own", isSearching: ownedCards.state.isSearching)
                }
            }
            if scope.showsOnline, let onlineCards, onlineCards.state != .idle {
                Section {
                    SearchResults(state: onlineCards.state, noResultsMessage: "No cards found online.") { results in
                        ForEach(results, id: \.card.id) { result in
                            OnlineCardRow(
                                card: OnlineCardPresentation(result),
                                addStatus: addToCollection?.status(for: result.card.id),
                                copies: addToCollection?.copies(for: result.card.id) ?? 1,
                                onIncrementCopies: { addToCollection?.incrementCopies(for: result.card.id) },
                                onDecrementCopies: { addToCollection?.decrementCopies(for: result.card.id) },
                                onAdd: { Task { await addToCollection?.add(result.card) } }
                            )
                        }
                    }
                } header: {
                    SearchSectionHeader(title: "Online", isSearching: onlineCards.state.isSearching)
                }
            }
        }
        .overlay {
            if areShownSectionsIdle {
                ContentUnavailableView(
                    "Search for Cards",
                    systemImage: "magnifyingglass",
                    description: Text("Type a card's name, number, set or rarity.")
                )
            }
        }
        .navigationTitle("Search")
        .onAppear { addToCollection = makeAddToCollection?() }
        .searchable(text: $query, prompt: "Name, number, set or rarity")
        .searchScopes($scope, isAvailable: ownedCards != nil && onlineCards != nil)
        // One task per section, so the cards you own never wait for the network.
        // A new query cancels the old tasks, so only the latest one is searched.
        .task(id: ownedQuery) {
            guard let ownedQuery else { return }
            await afterTypingPause { await ownedCards?.search(ownedQuery) }
        }
        .task(id: onlineQuery) {
            guard let onlineQuery else { return }
            await afterTypingPause { await onlineCards?.search(onlineQuery) }
        }
    }

    private var ownedQuery: String? { scope.showsOwned ? query : nil }
    private var onlineQuery: String? { scope.showsOnline ? query : nil }

    private var areShownSectionsIdle: Bool {
        let ownedIsIdle = !scope.showsOwned || (ownedCards?.state ?? .idle) == .idle
        let onlineIsIdle = !scope.showsOnline || (onlineCards?.state ?? .idle) == .idle
        return ownedIsIdle && onlineIsIdle
    }

    private func afterTypingPause(_ search: () async -> Void) async {
        // Throws when cancelled, i.e. the user kept typing.
        guard (try? await Task.sleep(for: .milliseconds(500))) != nil else { return }
        await search()
    }
}

/// One section's results, or why there are none.
struct SearchResults<Item: Equatable, Rows: View>: View {
    let state: SearchSectionViewModel<Item>.State
    let noResultsMessage: LocalizedStringKey
    @ViewBuilder let rows: ([Item]) -> Rows

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case let .searching(previous) where previous.isEmpty:
            ProgressView()
                .frame(maxWidth: .infinity)
        case let .searching(items), let .loaded(items):
            if items.isEmpty {
                Text(noResultsMessage)
                    .foregroundStyle(.secondary)
            } else {
                rows(items)
            }
        case .failed:
            Label("Couldn't search. Please try again.", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        }
    }
}

struct SearchSectionHeader: View {
    let title: LocalizedStringKey
    let isSearching: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            // While the results of the search before stay on screen.
            if isSearching {
                ProgressView()
                    .controlSize(.mini)
            }
        }
    }
}

struct OwnedCardGroupRow: View {
    let card: OwnedCardGroupPresentation

    var body: some View {
        CardRow(name: card.name, details: card.details, imageURL: card.imageURL) {
            Text(card.copies)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }
}

struct OnlineCardRow: View {
    let card: OnlineCardPresentation
    /// How adding the card to the collection is going, or nil to show no add controls.
    var addStatus: AddToCollectionViewModel.Status?
    var copies = 1
    var onIncrementCopies: () -> Void = {}
    var onDecrementCopies: () -> Void = {}
    var onAdd: () -> Void = {}

    // As wide as a chat tile, which fits "− 9 +" and "Added" on one line.
    private static var controlWidth: CGFloat { 120 }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            CardRow(name: card.name, details: card.details, imageURL: card.imageURL) {
                Text(card.price)
                    .font(.subheadline.monospacedDigit())
            }
            // Apart from the row's details, so VoiceOver reads them as their own controls.
            if let addStatus {
                HStack(spacing: 12) {
                    CopiesStepper(
                        copies: copies,
                        range: AddToCollectionViewModel.copiesRange,
                        // The count saved, or being saved, stays as it is.
                        isEnabled: addStatus == .notAdded || addStatus == .failed,
                        onIncrement: onIncrementCopies,
                        onDecrement: onDecrementCopies
                    )
                    .frame(width: Self.controlWidth)
                    AddToCollectionButton(status: addStatus, action: onAdd)
                        .lineLimit(1)
                        .frame(width: Self.controlWidth)
                }
            }
        }
    }
}

/// A card's image, name and details, with something at the trailing edge, e.g. its price.
struct CardRow<Trailing: View>: View {
    let name: String
    let details: String?
    let imageURL: URL?
    @ViewBuilder let trailing: () -> Trailing

    // A trading card's 63 × 88 mm shape.
    private static var imageSize: CGSize { CGSize(width: 44, height: 62) }

    var body: some View {
        HStack(spacing: 12) {
            CardImageView(url: imageURL)
                .frame(width: Self.imageSize.width, height: Self.imageSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                if let details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing()
        }
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    @ViewBuilder
    func searchScopes(_ scope: Binding<SearchScope>, isAvailable: Bool) -> some View {
        if isAvailable {
            searchScopes(scope) {
                Text("All").tag(SearchScope.all)
                Text("Your cards").tag(SearchScope.owned)
                Text("Online").tag(SearchScope.online)
            }
        } else {
            self
        }
    }
}

private extension SearchSectionViewModel.State {
    var isSearching: Bool {
        if case .searching = self { true } else { false }
    }
}

#if DEBUG
private let previewCards = [
    Card(id: 1, name: "Monkey.D.Luffy", number: "OP01-024", rarity: "L"),
    Card(id: 2, name: "Monkey.D.Luffy", number: "OP05-119", rarity: "SEC"),
    Card(id: 3, name: "Luffy & Ace, a card with a long name", number: "OP02-013", rarity: "SR"),
]

#Preview("Results") {
    NavigationStack {
        CardSearchView(
            ownedCards: SearchSectionViewModel { _ in
                OwnedCardGroup.groups(from: [previewCards[0], previewCards[0], previewCards[0], previewCards[2]].map { OwnedCard(card: $0) })
            },
            onlineCards: SearchSectionViewModel { _ in
                previewCards.enumerated().map { index, card in
                    CardSearchResult(
                        card: card,
                        price: index == 1 ? nil : PricePoint(cardID: card.id, date: .now, price: Money(amount: Decimal(index) * 20 + 1.5, currencyCode: "USD"))
                    )
                }
            },
            query: "luffy"
        )
    }
}

#Preview("Nothing found") {
    NavigationStack {
        CardSearchView(
            ownedCards: SearchSectionViewModel { _ in [] },
            onlineCards: SearchSectionViewModel { _ in throw CancellationError() },
            query: "zzz"
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        CardSearchView(ownedCards: SearchSectionViewModel { _ in [] }, onlineCards: SearchSectionViewModel { _ in [] })
    }
}
#endif
