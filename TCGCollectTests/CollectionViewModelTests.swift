//
//  CollectionViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

// The loader spy holds loads until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CollectionViewModelTests {

    @Test func init_startsIdleWithoutLoading() {
        let (sut, loader) = makeSUT()

        #expect(sut.state == .idle)
        #expect(loader.loadCount == 0)
    }

    @Test func load_requestsOwnedCards() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .success([]))

        #expect(loader.loadCount == 1)
    }

    @Test func load_isLoadingWhileWaitingForFirstLoad() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoading(sut, loader: loader)
        #expect(sut.state == .loading)

        loader.complete(with: .success([]))
        await loading.value
    }

    @Test func load_deliversOwnedCardsOnLoaderSuccess() async {
        let ownedCards = [makeOwnedCard(cardID: 1), makeOwnedCard(cardID: 2)]
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .success(ownedCards))

        #expect(sut.state == .loaded(ownedCards))
    }

    @Test func load_deliversNoOwnedCardsForEmptyCollection() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .success([]))

        #expect(sut.state == .loaded([]))
    }

    @Test func load_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.state == .failed)
    }

    // Reloads each time the tab appears, so the cards stay on screen instead of flashing back to a spinner.
    @Test func load_keepsShowingOwnedCardsWhileReloading() async {
        let ownedCards = [makeOwnedCard(cardID: 1)]
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success(ownedCards))

        let reloading = await startLoading(sut, loader: loader, at: 1)
        #expect(sut.state == .reloading(ownedCards))

        loader.complete(with: .success(ownedCards), at: 1)
        await reloading.value
    }

    @Test func load_deliversReloadedOwnedCards() async {
        let reloaded = [makeOwnedCard(cardID: 1), makeOwnedCard(cardID: 2)]
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 1)]))

        let reloading = await startLoading(sut, loader: loader, at: 1)
        loader.complete(with: .success(reloaded), at: 1)
        await reloading.value

        #expect(sut.state == .loaded(reloaded))
    }

    // Slightly out-of-date cards are more useful than an error.
    @Test func load_keepsShowingOwnedCardsWhenReloadFails() async {
        let ownedCards = [makeOwnedCard(cardID: 1)]
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success(ownedCards))

        let reloading = await startLoading(sut, loader: loader, at: 1)
        loader.complete(with: .failure(anyError()), at: 1)
        await reloading.value

        #expect(sut.state == .loaded(ownedCards))
    }

    @Test func load_ignoresLoadWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoading(sut, loader: loader)

        // In its own task: if it wrongly reached the loader, awaiting it here would never return.
        let secondLoading = Task { await sut.load() }
        await giveTimeToReachLoader(loader, loadCount: 2)
        #expect(loader.loadCount == 1)

        loader.completeAllPending(with: .success([]))
        await firstLoading.value
        await secondLoading.value
    }

    @Test func load_ignoresLoadWhileReloading() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 1)]))
        let reloading = await startLoading(sut, loader: loader, at: 1)

        // In its own task: if it wrongly reached the loader, awaiting it here would never return.
        let secondReloading = Task { await sut.load() }
        await giveTimeToReachLoader(loader, loadCount: 3)
        #expect(loader.loadCount == 2)

        loader.completeAllPending(with: .success([]))
        await reloading.value
        await secondReloading.value
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: CollectionViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CollectionViewModel(loader: loader)
        return (sut, loader)
    }

    private func makeOwnedCard(cardID: Int) -> OwnedCard {
        OwnedCard(card: Card(id: cardID, name: "card \(cardID)"))
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Starts loading and returns once the loader has received load number `index`, which is still waiting.
    private func startLoading(_ sut: CollectionViewModel, loader: LoaderSpy, at index: Int = 0) async -> Task<Void, Never> {
        let loading = Task { await sut.load() }
        for _ in 0..<1_000 where loader.loadCount <= index {
            await Task.yield()
        }
        #expect(loader.loadCount == index + 1, "Expected the loader to receive load \(index)")
        return loading
    }

    /// For a load that should be ignored: waits a bounded time for the loader to get `loadCount` loads anyway,
    /// so a load that wrongly goes through has the chance to show up before the test checks.
    private func giveTimeToReachLoader(_ loader: LoaderSpy, loadCount: Int) async {
        for _ in 0..<1_000 where loader.loadCount < loadCount {
            await Task.yield()
        }
    }

    private func load(_ sut: CollectionViewModel, loader: LoaderSpy, completingWith result: Result<[OwnedCard], Error>) async {
        let loading = await startLoading(sut, loader: loader)
        loader.complete(with: result)
        await loading.value
    }

    /// Holds every `load` call until the test completes it, so tests can look at the in-between state.
    @MainActor
    private final class LoaderSpy: OwnedCardLoader {
        // nil once completed, so no load is resumed twice.
        private var completions = [CheckedContinuation<[OwnedCard], Error>?]()
        // Set by completeAllPending, so a load that arrives late doesn't wait forever.
        private var resultForLaterLoads: Result<[OwnedCard], Error>?

        var loadCount: Int { completions.count }

        func load() async throws -> [OwnedCard] {
            if let resultForLaterLoads {
                completions.append(nil)
                return try resultForLaterLoads.get()
            }
            return try await withCheckedThrowingContinuation { completions.append($0) }
        }

        func complete(with result: Result<[OwnedCard], Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting load at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }

        /// Completes every waiting load, and any that arrive later, with `result`.
        func completeAllPending(with result: Result<[OwnedCard], Error>) {
            resultForLaterLoads = result
            for index in completions.indices where completions[index] != nil {
                complete(with: result, at: index)
            }
        }
    }
}
