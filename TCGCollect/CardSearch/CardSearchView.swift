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
    let ownedCards: SearchSectionViewModel<OwnedCardGroup>?
    let onlineCards: SearchSectionViewModel<CardSearchResult>?
    /// Makes what adds online cards to the collection, or nil to show no add buttons, e.g. without a collection.
    var makeAddToCollection: (() -> AddToCollectionViewModel)?
    @State var query = ""
    // A fresh one each time the tab appears, so a card added on an earlier visit can be added again.
    @State private var addToCollection: AddToCollectionViewModel?
    @AppStorage("searchScope") private var scope = SearchScope.all

    var body: some View {
        List {
            ownedCardsSection
            onlineCardsSection
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
        .task(id: ownedQuery) {
            guard let ownedQuery else { return }
            await afterTypingPause { await ownedCards?.search(ownedQuery) }
        }
        .task(id: onlineQuery) {
            guard let onlineQuery else { return }
            await afterTypingPause { await onlineCards?.search(onlineQuery) }
        }
    }

    @ViewBuilder
    private var ownedCardsSection: some View {
        if scope.showsOwned, let ownedCards, ownedCards.state != .idle {
            Section {
                SearchResults(state: ownedCards.state, noResultsMessage: "None of your cards match.") { groups in
                    ForEach(groups.map(OwnedCardGroupPresentation.init)) { OwnedCardGroupRow(card: $0) }
                }
            } header: {
                SearchSectionHeader(title: "Cards you own", isSearching: ownedCards.state.isSearching)
            }
        }
    }

    @ViewBuilder
    private var onlineCardsSection: some View {
        if scope.showsOnline, let onlineCards, onlineCards.state != .idle {
            Section {
                SearchResults(state: onlineCards.state, noResultsMessage: "No cards found online.") { results in
                    ForEach(results, id: \.card.id) { result in
                        OnlineCardRow(card: OnlineCardPresentation(result), addControls: addToCollection?.controls(for: result.card))
                    }
                }
            } header: {
                SearchSectionHeader(title: "Online", isSearching: onlineCards.state.isSearching)
            }
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
