//
//  SearchSectionViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Testing
@testable import TCGCollect

// The search spy holds searches until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SearchSectionViewModelTests {

    @Test func init_startsIdleWithoutSearching() {
        let (sut, spy) = makeSUT()

        #expect(sut.state == .idle)
        #expect(spy.queries.isEmpty)
    }

    // One letter matches too many cards to be useful.
    @Test(arguments: ["", "L", "  L  ", "   "])
    func search_doesNotSearchQueryShorterThanTwoCharacters(query: String) async {
        let (sut, spy) = makeSUT()
        spy.setCompletionForNewSearches(to: .success([]))

        await sut.search(query)

        #expect(spy.queries.isEmpty)
        #expect(sut.state == .idle)
    }

    @Test func search_requestsTrimmedQuery() async {
        let (sut, spy) = makeSUT()

        await search(sut, for: "  lu  ", spy: spy, completingWith: .success([]))

        #expect(spy.queries == ["lu"])
    }

    @Test func search_isSearchingWhileWaitingForFirstResults() async {
        let (sut, spy) = makeSUT()

        let searching = await startSearching(sut, for: "luffy", spy: spy)
        #expect(sut.state == .searching(previous: []))

        spy.complete(with: .success([]))
        await searching.value
    }

    @Test func search_deliversResultsOnSearchSuccess() async {
        let (sut, spy) = makeSUT()

        await search(sut, for: "luffy", spy: spy, completingWith: .success(["Luffy", "Luffy Leader"]))

        #expect(sut.state == .loaded(["Luffy", "Luffy Leader"]))
    }

    @Test func search_failsOnSearchFailure() async {
        let (sut, spy) = makeSUT()

        await search(sut, for: "luffy", spy: spy, completingWith: .failure(anyError()))

        #expect(sut.state == .failed)
    }

    // Results update while the user types, so the list stays on screen instead of flashing empty.
    @Test func search_keepsShowingResultsWhileSearchingAgain() async {
        let (sut, spy) = makeSUT()
        await search(sut, for: "lu", spy: spy, completingWith: .success(["Luffy"]))

        let searching = await startSearching(sut, for: "luf", spy: spy, at: 1)
        #expect(sut.state == .searching(previous: ["Luffy"]))

        spy.complete(with: .success([]), at: 1)
        await searching.value
    }

    // Like clearing the search field.
    @Test func search_goesBackToIdleForShortQueryAfterResults() async {
        let (sut, spy) = makeSUT()
        await search(sut, for: "luffy", spy: spy, completingWith: .success(["Luffy"]))

        await sut.search("")

        #expect(sut.state == .idle)
    }

    // The view cancels the search when the user keeps typing, but a search that's already running may still return results.
    @Test func search_keepsPreviousResultsWhenCancelledSearchStillDeliversResults() async {
        let (sut, spy) = makeSUT()
        await search(sut, for: "lu", spy: spy, completingWith: .success(["Luffy"]))

        let searching = await startSearching(sut, for: "luf", spy: spy, at: 1)
        searching.cancel()
        spy.complete(with: .success(["Luffy Leader"]), at: 1)
        await searching.value

        #expect(sut.state == .loaded(["Luffy"]))
    }

    // A cancelled network search throws, but the user asked for it to stop: not an error to show.
    @Test func search_doesNotFailWhenCancelledSearchFails() async {
        let (sut, spy) = makeSUT()

        let searching = await startSearching(sut, for: "luffy", spy: spy)
        searching.cancel()
        spy.complete(with: .failure(CancellationError()))
        await searching.value

        #expect(sut.state == .idle)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: SearchSectionViewModel<String>, spy: SearchSpy) {
        let spy = SearchSpy()
        let sut = SearchSectionViewModel(search: spy.search)
        return (sut, spy)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Starts searching and returns once the spy has received search number `index`, which is still waiting.
    private func startSearching(
        _ sut: SearchSectionViewModel<String>, for query: String, spy: SearchSpy, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let searching = Task { await sut.search(query) }
        await spy.waitForSearch(at: index, sourceLocation: sourceLocation)
        return searching
    }

    private func search(
        _ sut: SearchSectionViewModel<String>, for query: String, spy: SearchSpy,
        completingWith result: Result<[String], Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let searching = await startSearching(sut, for: query, spy: spy, sourceLocation: sourceLocation)
        spy.complete(with: result)
        await searching.value
    }

    /// Holds every search until the test completes it, so tests can look at the in-between state.
    @MainActor
    private final class SearchSpy {
        private(set) var queries = [String]()
        // nil once completed, so no search is resumed twice.
        private var completions = [CheckedContinuation<[String], Error>?]()
        private var resultForNewSearches: Result<[String], Error>?
        private let arrivals = CallArrivals(callName: "search")

        func search(_ query: String) async throws -> [String] {
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
        /// but reaches the spy anyway shows up in `queries` instead of leaving the test waiting.
        func setCompletionForNewSearches(to result: Result<[String], Error>) {
            resultForNewSearches = result
        }

        func complete(with result: Result<[String], Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting search at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }
    }
}
