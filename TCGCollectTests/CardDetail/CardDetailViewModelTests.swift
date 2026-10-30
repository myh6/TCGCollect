//
//  CardDetailViewModelTests.swift
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
struct CardDetailViewModelTests {

    @Test func init_showsCardWithoutLoadingDetails() {
        let card = Card(id: 7, name: "Roronoa Zoro", number: "OP01-025", rarity: "SR", printing: "Foil")
        let (sut, loader) = makeSUT(card: card)

        #expect(sut.card == CardDetailPresentation(card))
        #expect(sut.details == .idle)
        #expect(loader.requestedCardIDs.isEmpty)
    }

    @Test func loadDetails_requestsDetailsForCardID() async {
        let (sut, loader) = makeSUT(card: Card(id: 7, name: "Roronoa Zoro"))

        await loadDetails(sut, loader: loader, completingWith: .success(nil))

        #expect(loader.requestedCardIDs == [7])
    }

    @Test func loadDetails_isLoadingWhileWaitingForDetails() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoadingDetails(sut, loader: loader)
        #expect(sut.details == .loading)

        loader.complete(with: .success(nil))
        await loading.value
    }

    @Test func loadDetails_deliversDetailsOnLoaderSuccess() async {
        let details = GameDetails.onePiece(OnePieceDetails(category: .character, colors: [.green], power: 4000))
        let (sut, loader) = makeSUT()

        await loadDetails(sut, loader: loader, completingWith: .success(details))

        #expect(sut.details == .loaded(details))
    }

    @Test func loadDetails_deliversNoDetailsWhenCardHasNone() async {
        let (sut, loader) = makeSUT()

        await loadDetails(sut, loader: loader, completingWith: .success(nil))

        #expect(sut.details == .loaded(nil))
    }

    @Test func loadDetails_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await loadDetails(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.details == .failed)
    }

    @Test func loadDetails_ignoresLoadWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoadingDetails(sut, loader: loader)
        loader.setCompletionForNewRequests(to: .success(nil))

        await sut.loadDetails()
        #expect(loader.requestedCardIDs.count == 1)

        loader.complete(with: .success(nil))
        await firstLoading.value
    }

    @Test func loadDetails_doesNotReloadLoadedDetails() async {
        let (sut, loader) = makeSUT()
        await loadDetails(sut, loader: loader, completingWith: .success(nil))
        loader.setCompletionForNewRequests(to: .success(nil))

        await sut.loadDetails()

        #expect(loader.requestedCardIDs.count == 1)
    }

    @Test func loadDetails_retriesAfterFailure() async {
        let details = GameDetails.onePiece(OnePieceDetails(category: .event, colors: [.red]))
        let (sut, loader) = makeSUT()
        await loadDetails(sut, loader: loader, completingWith: .failure(anyError()))
        loader.setCompletionForNewRequests(to: .success(details))

        await sut.loadDetails()

        #expect(loader.requestedCardIDs.count == 2)
        #expect(sut.details == .loaded(details))
    }

    // MARK: - Helpers
    private func makeSUT(card: Card = Card(id: 1, name: "a card")) -> (sut: CardDetailViewModel, loader: DetailsLoaderSpy) {
        let loader = DetailsLoaderSpy()
        let sut = CardDetailViewModel(card: card, loader: loader)
        return (sut, loader)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoadingDetails(
        _ sut: CardDetailViewModel, loader: DetailsLoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.loadDetails() }
        await loader.waitForRequest(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func loadDetails(
        _ sut: CardDetailViewModel, loader: DetailsLoaderSpy, completingWith result: Result<GameDetails?, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoadingDetails(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    @MainActor
    private final class DetailsLoaderSpy: CardDetailsLoader {
        private(set) var requestedCardIDs = [Card.ID]()
        private var completions = [CheckedContinuation<GameDetails?, Error>?]()
        private var resultForNewRequests: Result<GameDetails?, Error>?
        private let arrivals = CallArrivals(callName: "loadDetails")

        func loadDetails(for cardID: Card.ID) async throws -> GameDetails? {
            requestedCardIDs.append(cardID)
            arrivals.record()
            if let resultForNewRequests {
                completions.append(nil)
                return try resultForNewRequests.get()
            }
            return try await withCheckedThrowingContinuation { completions.append($0) }
        }

        func waitForRequest(at index: Int, sourceLocation: SourceLocation = #_sourceLocation) async {
            await arrivals.waitForCall(at: index, sourceLocation: sourceLocation)
        }

        func setCompletionForNewRequests(to result: Result<GameDetails?, Error>) {
            resultForNewRequests = result
        }

        func complete(with result: Result<GameDetails?, Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting request at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }
    }
}
