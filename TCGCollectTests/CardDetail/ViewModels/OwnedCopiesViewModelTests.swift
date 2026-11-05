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
        let (sut, counter, _) = makeSUT()

        #expect(sut.copies == .idle)
        #expect(counter.countCount == 0)
    }

    @Test func load_isLoadingWhileCounting() async {
        let (sut, counter, _) = makeSUT()

        let loading = await startLoading(sut, counter: counter)
        #expect(sut.copies == .loading)

        counter.complete(with: .success(0))
        await loading.value
    }

    @Test func load_countsThisCardsCopies() async {
        let (sut, counter, _) = makeSUT(cardID: 7)

        await load(sut, counter: counter, completingWith: .success(2))

        #expect(counter.countedCardIDs == [7])
        #expect(sut.copies == .loaded(2))
    }

    @Test func load_failsOnLoaderFailure() async {
        let (sut, counter, _) = makeSUT()

        await load(sut, counter: counter, completingWith: .failure(anyError()))

        #expect(sut.copies == .failed)
    }

    @Test func load_ignoresLoadWhileLoading() async {
        let (sut, counter, _) = makeSUT()
        let firstLoading = await startLoading(sut, counter: counter)
        counter.setCompletionForNewCalls(to: .success(0))

        await sut.load()
        #expect(counter.countCount == 1)

        counter.complete(with: .success(0))
        await firstLoading.value
    }

    @Test func load_doesNotRecountLoadedCopies() async {
        let (sut, counter, _) = makeSUT()
        await load(sut, counter: counter, completingWith: .success(0))
        counter.setCompletionForNewCalls(to: .success(0))

        await sut.load()

        #expect(counter.countCount == 1)
    }

    @Test func refresh_keepsShowingCountWhileRecounting() async {
        let (sut, counter, _) = makeSUT(cardID: 7)
        await load(sut, counter: counter, completingWith: .success(1))

        let refreshing = Task { await sut.refresh() }
        await counter.waitForCall(at: 1)
        #expect(sut.copies == .loaded(1))

        counter.complete(with: .success(2), at: 1)
        await refreshing.value
        #expect(sut.copies == .loaded(2))
    }

    @Test func refresh_keepsCountWhenRecountFails() async {
        let (sut, counter, _) = makeSUT(cardID: 7)
        await load(sut, counter: counter, completingWith: .success(1))
        counter.setCompletionForNewCalls(to: .failure(anyError()))

        await sut.refresh()

        #expect(sut.copies == .loaded(1))
    }

    @Test func refresh_countsWhenNothingCountedYet() async {
        let (sut, counter, _) = makeSUT(cardID: 7)
        counter.setCompletionForNewCalls(to: .success(1))

        await sut.refresh()

        #expect(sut.copies == .loaded(1))
    }

    @Test func start_listensForChangesBeforeCounting() async {
        let (sut, counter, observer) = makeSUT()

        let starting = Task { await sut.start() }
        await counter.waitForCall(at: 0)
        #expect(observer.listenCount == 1)

        counter.complete(with: .success(0))
        observer.finish()
        await starting.value
    }

    @Test func start_recountsAfterEveryChange() async {
        let (sut, counter, observer) = makeSUT()
        let starting = Task { await sut.start() }
        await counter.waitForCall(at: 0)
        counter.complete(with: .success(1))

        observer.announceChange()
        await counter.waitForCall(at: 1)
        counter.complete(with: .success(2), at: 1)
        observer.announceChange()
        await counter.waitForCall(at: 2)
        counter.complete(with: .success(3), at: 2)
        observer.finish()
        await starting.value

        #expect(sut.copies == .loaded(3))
    }

    @Test func start_returnsOnceChangesEnd() async {
        let (sut, counter, observer) = makeSUT()
        counter.setCompletionForNewCalls(to: .success(0))
        observer.finish()

        await sut.start()

        #expect(sut.copies == .loaded(0))
    }

    // MARK: - Helpers
    private func makeSUT(cardID: Card.ID = 1) -> (sut: OwnedCopiesViewModel, counter: CopyCounterSpy, observer: ChangeObserverStub) {
        let counter = CopyCounterSpy()
        let observer = ChangeObserverStub()
        let sut = OwnedCopiesViewModel(cardID: cardID, counter: counter, observer: observer)
        return (sut, counter, observer)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoading(
        _ sut: OwnedCopiesViewModel, counter: CopyCounterSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.load() }
        await counter.waitForCall(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func load(
        _ sut: OwnedCopiesViewModel, counter: CopyCounterSpy, completingWith result: Result<Int, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoading(sut, counter: counter, sourceLocation: sourceLocation)
        counter.complete(with: result)
        await loading.value
    }

    private final class CopyCounterSpy: HeldCalls<Card.ID, Int>, OwnedCardCopyCounter {
        var countedCardIDs: [Card.ID] { inputs }
        var countCount: Int { inputs.count }

        init() {
            super.init(callName: "countCopies")
        }

        func countCopies(of cardID: Card.ID) async throws -> Int {
            try await call(with: cardID)
        }
    }
}
