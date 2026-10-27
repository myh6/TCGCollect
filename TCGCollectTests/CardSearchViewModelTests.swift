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

// The searcher spy holds searches until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CardSearchViewModelTests {

    @Test func init_startsIdleWithoutSearching() {
        let (sut, ownedSearcher) = makeSUT()

        #expect(sut.ownedCards == .idle)
        #expect(ownedSearcher.queries.isEmpty)
    }

    // One letter matches too many cards to be useful.
    @Test(arguments: ["", "L", "  L  ", "   "])
    func search_doesNotSearchQueryShorterThanTwoCharacters(query: String) async {
        let (sut, ownedSearcher) = makeSUT()
        ownedSearcher.setCompletionForNewSearches(to: .success([]))

        await sut.search(query)

        #expect(ownedSearcher.queries.isEmpty)
        #expect(sut.ownedCards == .idle)
    }

    @Test func search_requestsOwnedCardsWithTrimmedQuery() async {
        let (sut, ownedSearcher) = makeSUT()

        await search(sut, for: "  lu  ", ownedSearcher: ownedSearcher, completingWith: .success([]))

        #expect(ownedSearcher.queries == ["lu"])
    }

    @Test func search_isSearchingWhileWaitingForFirstOwnedCards() async {
        let (sut, ownedSearcher) = makeSUT()

        let searching = await startSearching(sut, for: "luffy", ownedSearcher: ownedSearcher)
        #expect(sut.ownedCards == .searching(previous: []))

        ownedSearcher.complete(with: .success([]))
        await searching.value
    }

    @Test func search_deliversOwnedCopiesGroupedByCard() async {
        let luffy = makeCard(id: 1, name: "Monkey D. Luffy")
        let zoro = makeCard(id: 2, name: "Roronoa Zoro")
        let (sut, ownedSearcher) = makeSUT()

        await search(sut, for: "on", ownedSearcher: ownedSearcher, completingWith: .success([
            OwnedCard(card: luffy), OwnedCard(card: zoro), OwnedCard(card: luffy),
        ]))

        #expect(sut.ownedCards == .loaded([
            OwnedCardGroup(card: luffy, count: 2), OwnedCardGroup(card: zoro, count: 1),
        ]))
    }

    @Test func search_failsOnOwnedSearcherFailure() async {
        let (sut, ownedSearcher) = makeSUT()

        await search(sut, for: "luffy", ownedSearcher: ownedSearcher, completingWith: .failure(anyError()))

        #expect(sut.ownedCards == .failed)
    }

    // Results update while the user types, so the list stays on screen instead of flashing empty.
    @Test func search_keepsShowingOwnedCardsWhileSearchingAgain() async {
        let luffy = makeCard(id: 1, name: "Monkey D. Luffy")
        let (sut, ownedSearcher) = makeSUT()
        await search(sut, for: "lu", ownedSearcher: ownedSearcher, completingWith: .success([OwnedCard(card: luffy)]))

        let searching = await startSearching(sut, for: "luf", ownedSearcher: ownedSearcher, at: 1)
        #expect(sut.ownedCards == .searching(previous: [OwnedCardGroup(card: luffy, count: 1)]))

        ownedSearcher.complete(with: .success([]), at: 1)
        await searching.value
    }

    // Like clearing the search field.
    @Test func search_goesBackToIdleForShortQueryAfterResults() async {
        let (sut, ownedSearcher) = makeSUT()
        await search(sut, for: "luffy", ownedSearcher: ownedSearcher, completingWith: .success([OwnedCard(card: makeCard(id: 1))]))

        await sut.search("")

        #expect(sut.ownedCards == .idle)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: CardSearchViewModel, ownedSearcher: OwnedCardSearcherSpy) {
        let ownedSearcher = OwnedCardSearcherSpy()
        let sut = CardSearchViewModel(ownedCardSearcher: ownedSearcher)
        return (sut, ownedSearcher)
    }

    private func makeCard(id: Int, name: String? = nil) -> Card {
        Card(id: id, name: name ?? "card \(id)")
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Starts searching and returns once the searcher has received search number `index`, which is still waiting.
    private func startSearching(
        _ sut: CardSearchViewModel, for query: String, ownedSearcher: OwnedCardSearcherSpy, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let searching = Task { await sut.search(query) }
        await ownedSearcher.waitForSearch(at: index, sourceLocation: sourceLocation)
        return searching
    }

    private func search(
        _ sut: CardSearchViewModel, for query: String, ownedSearcher: OwnedCardSearcherSpy,
        completingWith result: Result<[OwnedCard], Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let searching = await startSearching(sut, for: query, ownedSearcher: ownedSearcher, sourceLocation: sourceLocation)
        ownedSearcher.complete(with: result)
        await searching.value
    }

    /// Holds every `search` call until the test completes it, so tests can look at the in-between state.
    @MainActor
    private final class OwnedCardSearcherSpy: OwnedCardSearcher {
        private(set) var queries = [String]()
        // nil once completed, so no search is resumed twice.
        private var completions = [CheckedContinuation<[OwnedCard], Error>?]()
        private var resultForNewSearches: Result<[OwnedCard], Error>?
        private let arrivals = CallArrivals(callName: "search")

        func search(_ query: String) async throws -> [OwnedCard] {
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
        func setCompletionForNewSearches(to result: Result<[OwnedCard], Error>) {
            resultForNewSearches = result
        }

        func complete(with result: Result<[OwnedCard], Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting search at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }
    }
}
