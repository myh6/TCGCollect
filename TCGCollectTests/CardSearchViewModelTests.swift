//
//  CardSearchViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

// The searcher spies hold searches until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CardSearchViewModelTests {

    @Test func init_startsIdleWithoutSearching() {
        let (sut, owned, online) = makeSUT()

        #expect(sut.ownedCards == .idle)
        #expect(sut.onlineCards == .idle)
        #expect(owned.queries.isEmpty)
        #expect(online.queries.isEmpty)
    }

    // One letter matches too many cards to be useful.
    @Test(arguments: ["", "L", "  L  ", "   "])
    func search_doesNotSearchQueryShorterThanTwoCharacters(query: String) async {
        let (sut, owned, online) = makeSUT()
        owned.setCompletionForNewSearches(to: .success([]))
        online.setCompletionForNewSearches(to: .success([]))

        await sut.search(query)

        #expect(owned.queries.isEmpty)
        #expect(online.queries.isEmpty)
        #expect(sut.ownedCards == .idle)
        #expect(sut.onlineCards == .idle)
    }

    @Test func search_requestsBothSearchersWithTrimmedQuery() async {
        let (sut, owned, online) = makeSUT()

        await search(sut, for: "  lu  ", owned: owned, online: online)

        #expect(owned.queries == ["lu"])
        #expect(online.queries == ["lu"])
    }

    @Test func search_isSearchingBothSectionsWhileWaitingForFirstResults() async {
        let (sut, owned, online) = makeSUT()

        let searching = await startSearching(sut, for: "luffy", owned: owned, online: online)
        #expect(sut.ownedCards == .searching(previous: []))
        #expect(sut.onlineCards == .searching(previous: []))

        await complete(searching, owned: owned, online: online)
    }

    @Test func search_deliversOwnedCopiesGroupedByCard() async {
        let luffy = makeCard(id: 1, name: "Monkey D. Luffy")
        let zoro = makeCard(id: 2, name: "Roronoa Zoro")
        let (sut, owned, online) = makeSUT()

        await search(sut, for: "on", owned: owned, online: online, ownedResult: .success([
            OwnedCard(card: luffy), OwnedCard(card: zoro), OwnedCard(card: luffy),
        ]))

        #expect(sut.ownedCards == .loaded([
            OwnedCardGroup(card: luffy, count: 2), OwnedCardGroup(card: zoro, count: 1),
        ]))
    }

    @Test func search_deliversOnlineResults() async {
        let results = [
            CardSearchResult(card: makeCard(id: 1), price: PricePoint(cardID: 1, date: Date(timeIntervalSince1970: 0), price: Money(amount: 42.5, currencyCode: "USD"))),
            CardSearchResult(card: makeCard(id: 2), price: nil),
        ]
        let (sut, owned, online) = makeSUT()

        await search(sut, for: "luffy", owned: owned, online: online, onlineResult: .success(results))

        #expect(sut.onlineCards == .loaded(results))
    }

    // The two sections don't depend on each other, so one failing still shows the other.
    @Test func search_failsOnlyOwnedSectionOnOwnedSearcherFailure() async {
        let results = [CardSearchResult(card: makeCard(id: 1), price: nil)]
        let (sut, owned, online) = makeSUT()

        await search(sut, for: "luffy", owned: owned, online: online, ownedResult: .failure(anyError()), onlineResult: .success(results))

        #expect(sut.ownedCards == .failed)
        #expect(sut.onlineCards == .loaded(results))
    }

    @Test func search_failsOnlyOnlineSectionOnOnlineSearcherFailure() async {
        let luffy = makeCard(id: 1)
        let (sut, owned, online) = makeSUT()

        await search(sut, for: "luffy", owned: owned, online: online, ownedResult: .success([OwnedCard(card: luffy)]), onlineResult: .failure(anyError()))

        #expect(sut.ownedCards == .loaded([OwnedCardGroup(card: luffy, count: 1)]))
        #expect(sut.onlineCards == .failed)
    }

    // Results update while the user types, so the lists stay on screen instead of flashing empty.
    @Test func search_keepsShowingBothSectionsWhileSearchingAgain() async {
        let luffy = makeCard(id: 1)
        let onlineResults = [CardSearchResult(card: luffy, price: nil)]
        let (sut, owned, online) = makeSUT()
        await search(sut, for: "lu", owned: owned, online: online, ownedResult: .success([OwnedCard(card: luffy)]), onlineResult: .success(onlineResults))

        let searching = await startSearching(sut, for: "luf", owned: owned, online: online, at: 1)
        #expect(sut.ownedCards == .searching(previous: [OwnedCardGroup(card: luffy, count: 1)]))
        #expect(sut.onlineCards == .searching(previous: onlineResults))

        await complete(searching, owned: owned, online: online, at: 1)
    }

    // Like clearing the search field.
    @Test func search_goesBackToIdleForShortQueryAfterResults() async {
        let card = makeCard(id: 1)
        let (sut, owned, online) = makeSUT()
        await search(sut, for: "luffy", owned: owned, online: online, ownedResult: .success([OwnedCard(card: card)]), onlineResult: .success([CardSearchResult(card: card, price: nil)]))

        await sut.search("")

        #expect(sut.ownedCards == .idle)
        #expect(sut.onlineCards == .idle)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: CardSearchViewModel, owned: SearcherSpy<OwnedCard>, online: SearcherSpy<CardSearchResult>) {
        let owned = SearcherSpy<OwnedCard>()
        let online = SearcherSpy<CardSearchResult>()
        let sut = CardSearchViewModel(ownedCardSearcher: owned, cardSearcher: online)
        return (sut, owned, online)
    }

    private func makeCard(id: Int, name: String? = nil) -> Card {
        Card(id: id, name: name ?? "card \(id)")
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Starts searching and returns once both searchers have received search number `index`, which are still waiting.
    private func startSearching(
        _ sut: CardSearchViewModel, for query: String,
        owned: SearcherSpy<OwnedCard>, online: SearcherSpy<CardSearchResult>, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let searching = Task { await sut.search(query) }
        await owned.waitForSearch(at: index, sourceLocation: sourceLocation)
        await online.waitForSearch(at: index, sourceLocation: sourceLocation)
        return searching
    }

    private func complete(
        _ searching: Task<Void, Never>,
        owned: SearcherSpy<OwnedCard>, online: SearcherSpy<CardSearchResult>, at index: Int = 0,
        ownedResult: Result<[OwnedCard], Error> = .success([]),
        onlineResult: Result<[CardSearchResult], Error> = .success([])
    ) async {
        owned.complete(with: ownedResult, at: index)
        online.complete(with: onlineResult, at: index)
        await searching.value
    }

    private func search(
        _ sut: CardSearchViewModel, for query: String,
        owned: SearcherSpy<OwnedCard>, online: SearcherSpy<CardSearchResult>,
        ownedResult: Result<[OwnedCard], Error> = .success([]),
        onlineResult: Result<[CardSearchResult], Error> = .success([]),
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let searching = await startSearching(sut, for: query, owned: owned, online: online, sourceLocation: sourceLocation)
        await complete(searching, owned: owned, online: online, ownedResult: ownedResult, onlineResult: onlineResult)
    }

    /// Stands in for either searcher. Holds every `search` call until the test completes it,
    /// so tests can look at the in-between state.
    @MainActor
    fileprivate final class SearcherSpy<Item> {
        private(set) var queries = [String]()
        // nil once completed, so no search is resumed twice.
        private var completions = [CheckedContinuation<[Item], Error>?]()
        private var resultForNewSearches: Result<[Item], Error>?
        private let arrivals = CallArrivals(callName: "search")

        func search(_ query: String) async throws -> [Item] {
            queries.append(query)
            arrivals.record()
            if let resultForNewSearches {
                completions.append(nil)
                return try resultForNewSearches.get()
            }
            return try await withCheckedThrowingContinuation { completions.append($0) }
        }

        func waitForSearch(at index: Int, sourceLocation: SourceLocation = #_sourceLocation) async {
            await arrivals.waitForCall(at: index, sourceLocation: sourceLocation)
        }

        /// Searches that arrive from now on complete right away, so a search that should be skipped
        /// but reaches the searcher anyway shows up in `queries` instead of leaving the test waiting.
        func setCompletionForNewSearches(to result: Result<[Item], Error>) {
            resultForNewSearches = result
        }

        func complete(with result: Result<[Item], Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting search at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }
    }
}

extension CardSearchViewModelTests.SearcherSpy: OwnedCardSearcher where Item == OwnedCard {}
extension CardSearchViewModelTests.SearcherSpy: CardSearcher where Item == CardSearchResult {}
