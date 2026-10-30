//
//  OwnedCopiesViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct OwnedCopiesViewModelTests {

    @Test func init_startsIdleWithoutLoading() {
        let (sut, loader) = makeSUT()

        #expect(sut.copies == .idle)
        #expect(loader.loadCount == 0)
    }

    @Test func load_isLoadingWhileCounting() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoading(sut, loader: loader)
        #expect(sut.copies == .loading)

        loader.complete(with: .success([]))
        await loading.value
    }

    @Test func load_countsOnlyThisCardsCopies() async {
        let (sut, loader) = makeSUT(cardID: 7)

        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 7), makeOwnedCard(cardID: 8), makeOwnedCard(cardID: 7)]))

        #expect(sut.copies == .loaded(2))
    }

    @Test func load_countsNoCopiesWhenNotOwned() async {
        let (sut, loader) = makeSUT(cardID: 7)

        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 8)]))

        #expect(sut.copies == .loaded(0))
    }

    @Test func load_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.copies == .failed)
    }

    @Test func load_ignoresLoadWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoading(sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success([]))

        await sut.load()
        #expect(loader.loadCount == 1)

        loader.complete(with: .success([]))
        await firstLoading.value
    }

    @Test func load_doesNotRecountLoadedCopies() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([]))
        loader.setCompletionForNewCalls(to: .success([]))

        await sut.load()

        #expect(loader.loadCount == 1)
    }

    @Test func refresh_keepsShowingCountWhileRecounting() async {
        let (sut, loader) = makeSUT(cardID: 7)
        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 7)]))

        let refreshing = Task { await sut.refresh() }
        await loader.waitForCall(at: 1)
        #expect(sut.copies == .loaded(1))

        loader.complete(with: .success([makeOwnedCard(cardID: 7), makeOwnedCard(cardID: 7)]), at: 1)
        await refreshing.value
        #expect(sut.copies == .loaded(2))
    }

    @Test func refresh_keepsCountWhenRecountFails() async {
        let (sut, loader) = makeSUT(cardID: 7)
        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 7)]))
        loader.setCompletionForNewCalls(to: .failure(anyError()))

        await sut.refresh()

        #expect(sut.copies == .loaded(1))
    }

    @Test func refresh_countsWhenNothingCountedYet() async {
        let (sut, loader) = makeSUT(cardID: 7)
        loader.setCompletionForNewCalls(to: .success([makeOwnedCard(cardID: 7)]))

        await sut.refresh()

        #expect(sut.copies == .loaded(1))
    }

    // MARK: - Helpers
    private func makeSUT(cardID: Card.ID = 1) -> (sut: OwnedCopiesViewModel, loader: CollectionLoaderSpy) {
        let loader = CollectionLoaderSpy()
        let sut = OwnedCopiesViewModel(cardID: cardID, loader: loader)
        return (sut, loader)
    }

    private func makeOwnedCard(cardID: Card.ID) -> OwnedCard {
        OwnedCard(card: Card(id: cardID, name: "card \(cardID)"))
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoading(
        _ sut: OwnedCopiesViewModel, loader: CollectionLoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.load() }
        await loader.waitForCall(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func load(
        _ sut: OwnedCopiesViewModel, loader: CollectionLoaderSpy, completingWith result: Result<[OwnedCard], Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoading(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    private final class CollectionLoaderSpy: HeldCalls<Void, [OwnedCard]>, OwnedCardLoader {
        var loadCount: Int { inputs.count }

        init() {
            super.init(callName: "load")
        }

        func load() async throws -> [OwnedCard] {
            try await call(with: ())
        }
    }
}
