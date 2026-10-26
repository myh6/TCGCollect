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
        loader.setCompletionForNewLoads(to: .success([]))

        await sut.load()
        #expect(loader.loadCount == 1)

        loader.complete(with: .success([]))
        await firstLoading.value
    }

    @Test func load_ignoresLoadWhileReloading() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([makeOwnedCard(cardID: 1)]))
        let reloading = await startLoading(sut, loader: loader, at: 1)
        loader.setCompletionForNewLoads(to: .success([]))

        await sut.load()
        #expect(loader.loadCount == 2)

        loader.complete(with: .success([]), at: 1)
        await reloading.value
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
    private func startLoading(
        _ sut: CollectionViewModel, loader: LoaderSpy, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.load() }
        await loader.waitForLoad(at: index, sourceLocation: sourceLocation)
        return loading
    }

    private func load(
        _ sut: CollectionViewModel, loader: LoaderSpy, completingWith result: Result<[OwnedCard], Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoading(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    /// Holds every `load` call until the test completes it, so tests can look at the in-between state.
    @MainActor
    private final class LoaderSpy: OwnedCardLoader {
        // nil once completed, so no load is resumed twice.
        private var completions = [CheckedContinuation<[OwnedCard], Error>?]()
        private var resultForNewLoads: Result<[OwnedCard], Error>?
        // Tests waiting for a load to arrive, by the index of that load.
        private var arrivalWaiters = [Int: CheckedContinuation<Void, Never>]()

        private(set) var loadCount = 0

        func load() async throws -> [OwnedCard] {
            loadCount += 1
            arrivalWaiters.removeValue(forKey: loadCount - 1)?.resume()
            if let resultForNewLoads {
                completions.append(nil)
                return try resultForNewLoads.get()
            }
            return try await withCheckedThrowingContinuation { completions.append($0) }
        }

        /// Returns once load number `index` has arrived, or records an issue if it hasn't within `timeout`.
        func waitForLoad(
            at index: Int, timeout: Duration = .seconds(5),
            sourceLocation: SourceLocation = #_sourceLocation
        ) async {
            guard loadCount <= index else { return }
            let timeoutTask = Task { [weak self] in
                try await Task.sleep(for: timeout)
                guard let waiter = self?.arrivalWaiters.removeValue(forKey: index) else { return }
                Issue.record("Load \(index) never reached the loader", sourceLocation: sourceLocation)
                waiter.resume()
            }
            await withCheckedContinuation { arrivalWaiters[index] = $0 }
            timeoutTask.cancel()
        }

        /// Loads that arrive from now on complete right away, so a load that should be ignored
        /// but reaches the loader anyway shows up in `loadCount` instead of leaving the test waiting.
        /// Loads already waiting stay held until `complete(with:at:)`.
        func setCompletionForNewLoads(to result: Result<[OwnedCard], Error>) {
            resultForNewLoads = result
        }

        func complete(with result: Result<[OwnedCard], Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting load at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }
    }
}
