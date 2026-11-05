//
//  CardSetViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CardSetViewModelTests {

    @Test func init_showsSetWithoutLoadingCards() {
        let set = makeSet(id: 7)
        let (sut, loader) = makeSUT(set: set)

        #expect(sut.set == set)
        #expect(sut.cards == .idle)
        #expect(loader.inputs.isEmpty)
    }

    @Test func loadFirstPage_requestsFirstPageOfSet() async {
        let (sut, loader) = makeSUT(set: makeSet(id: 7))

        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [], total: 0)))

        #expect(loader.inputs.map(\.setID) == [7])
        #expect(loader.inputs.map(\.offset) == [0])
    }

    @Test func loadFirstPage_isLoadingWhileWaitingForCards() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoadingFirstPage(sut, loader: loader)
        #expect(sut.cards == .loading)

        loader.complete(with: .success(makePage(ids: [], total: 0)))
        await loading.value
    }

    @Test func loadFirstPage_deliversCardsOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()

        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1, 2], total: 2)))

        #expect(sut.cards == .loaded(makeResults(ids: [1, 2])))
    }

    @Test func loadFirstPage_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await loadFirstPage(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.cards == .failed)
    }

    @Test func loadFirstPage_ignoresLoadWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoadingFirstPage(sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [], total: 0)))

        await sut.loadFirstPage()
        #expect(loader.inputs.count == 1)

        loader.complete(with: .success(makePage(ids: [], total: 0)))
        await firstLoading.value
    }

    @Test func loadFirstPage_doesNotReloadLoadedCards() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 1)))
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [2], total: 1)))

        await sut.loadFirstPage()

        #expect(loader.inputs.count == 1)
    }

    @Test func loadFirstPage_retriesAfterFailure() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .failure(anyError()))
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [1], total: 1)))

        await sut.loadFirstPage()

        #expect(sut.cards == .loaded(makeResults(ids: [1])))
    }

    @Test(arguments: [(2, true), (1, false)])
    func hasMore_whenSetHasMoreCardsThanLoaded(total: Int, hasMore: Bool) async {
        let (sut, loader) = makeSUT()

        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: total)))

        #expect(sut.hasMore == hasMore)
    }

    @Test func hasMore_isFalseBeforeFirstPageLoads() {
        let (sut, _) = makeSUT()

        #expect(sut.hasMore == false)
    }

    @Test func loadMore_requestsNextPageAfterLoadedCards() async {
        let (sut, loader) = makeSUT(set: makeSet(id: 7))
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1, 2], total: 3)))

        await loadMore(sut, loader: loader, completingWith: .success(makePage(ids: [3], total: 3)))

        #expect(loader.inputs.map(\.setID) == [7, 7])
        #expect(loader.inputs.map(\.offset) == [0, 2])
    }

    @Test func loadMore_isLoadingMoreWhileWaitingAndKeepsShowingCards() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 2)))

        let loading = await startLoadingMore(sut, loader: loader)
        #expect(sut.more == .loading)
        #expect(sut.cards == .loaded(makeResults(ids: [1])))

        loader.complete(with: .success(makePage(ids: [2], total: 2)), at: 1)
        await loading.value
    }

    @Test func loadMore_appendsNextPageToCards() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 2)))

        await loadMore(sut, loader: loader, completingWith: .success(makePage(ids: [2], total: 2)))

        #expect(sut.cards == .loaded(makeResults(ids: [1, 2])))
        #expect(sut.more == .idle)
        #expect(sut.hasMore == false)
    }

    @Test func loadMore_keepsCardsAndFailsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 2)))

        await loadMore(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.cards == .loaded(makeResults(ids: [1])))
        #expect(sut.more == .failed)
        #expect(sut.hasMore == true)
    }

    @Test func loadMore_retriesAfterFailure() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 2)))
        await loadMore(sut, loader: loader, completingWith: .failure(anyError()))
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [2], total: 2)))

        await sut.loadMore()

        #expect(loader.inputs.map(\.offset) == [0, 1, 1])
        #expect(sut.cards == .loaded(makeResults(ids: [1, 2])))
        #expect(sut.more == .idle)
    }

    @Test func loadMore_ignoresLoadWhileLoadingMore() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 3)))
        let loading = await startLoadingMore(sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [], total: 3)))

        await sut.loadMore()
        #expect(loader.inputs.count == 2)

        loader.complete(with: .success(makePage(ids: [2], total: 3)), at: 1)
        await loading.value
    }

    @Test func loadMore_doesNothingWhenAllCardsAreLoaded() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 1)))
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [], total: 1)))

        await sut.loadMore()

        #expect(loader.inputs.count == 1)
    }

    @Test func loadMore_doesNothingBeforeFirstPageLoads() async {
        let (sut, loader) = makeSUT()
        loader.setCompletionForNewCalls(to: .success(makePage(ids: [], total: 0)))

        await sut.loadMore()

        #expect(loader.inputs.isEmpty)
    }

    // The set can shrink between pages; an empty page means there's nothing more to load.
    @Test func loadMore_stopsWhenPageIsEmpty() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1], total: 2)))

        await loadMore(sut, loader: loader, completingWith: .success(makePage(ids: [], total: 2)))

        #expect(sut.hasMore == false)
    }

    // The set can change between pages, which can shift a card already shown onto the next page.
    @Test func loadMore_skipsCardsAlreadyShown() async {
        let (sut, loader) = makeSUT()
        await loadFirstPage(sut, loader: loader, completingWith: .success(makePage(ids: [1, 2], total: 4)))

        await loadMore(sut, loader: loader, completingWith: .success(makePage(ids: [2, 3], total: 4)))

        #expect(sut.cards == .loaded(makeResults(ids: [1, 2, 3])))
    }

    // MARK: - Helpers
    private func makeSUT(set: CardSet? = nil) -> (sut: CardSetViewModel, loader: PageLoaderSpy) {
        let loader = PageLoaderSpy()
        let sut = CardSetViewModel(set: set ?? makeSet(id: 1), loader: loader)
        return (sut, loader)
    }

    private func makeSet(id: CardSet.ID) -> CardSet {
        CardSet(id: id, name: "a set", cardCount: 3, releaseDate: nil)
    }

    private func makeResults(ids: [Card.ID]) -> [CardSearchResult] {
        ids.map { CardSearchResult(card: Card(id: $0, name: "card \($0)"), price: nil) }
    }

    private func makePage(ids: [Card.ID], total: Int) -> CardSetPage {
        CardSetPage(cards: makeResults(ids: ids), totalCount: total)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoadingFirstPage(
        _ sut: CardSetViewModel, loader: PageLoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.loadFirstPage() }
        await loader.waitForCall(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func loadFirstPage(
        _ sut: CardSetViewModel, loader: PageLoaderSpy, completingWith result: Result<CardSetPage, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoadingFirstPage(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    private func startLoadingMore(
        _ sut: CardSetViewModel, loader: PageLoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let index = loader.inputs.count
        let loading = Task { await sut.loadMore() }
        await loader.waitForCall(at: index, sourceLocation: sourceLocation)
        return loading
    }

    private func loadMore(
        _ sut: CardSetViewModel, loader: PageLoaderSpy, completingWith result: Result<CardSetPage, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let index = loader.inputs.count
        let loading = await startLoadingMore(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result, at: index)
        await loading.value
    }

    private final class PageLoaderSpy: HeldCalls<(setID: CardSet.ID, offset: Int), CardSetPage>, CardSetPageLoader {
        init() {
            super.init(callName: "loadCards")
        }

        func loadCards(inSet setID: CardSet.ID, offset: Int) async throws -> CardSetPage {
            try await call(with: (setID, offset))
        }
    }
}
