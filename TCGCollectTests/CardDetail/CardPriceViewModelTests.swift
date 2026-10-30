//
//  CardPriceViewModelTests.swift
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
struct CardPriceViewModelTests {

    @Test func init_startsIdleOnOneMonthWithoutLoading() {
        let (sut, loader) = makeSUT()

        #expect(sut.history == .idle)
        #expect(sut.range == .month)
        #expect(loader.requests.isEmpty)
    }

    @Test func load_requestsThisCardsHistoryOverOneMonth() async {
        let (sut, loader) = makeSUT(cardID: 7)

        await load(sut, loader: loader, completingWith: .success([]))

        #expect(loader.requests == [HistoryRequest(cardIDs: [7], days: 30)])
    }

    @Test func load_isLoadingWhileWaitingForHistory() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoading(sut, loader: loader)
        #expect(sut.history == .loading)

        loader.complete(with: .success([]))
        await loading.value
    }

    @Test func load_deliversOnlyThisCardsPointsOldestFirst() async {
        let older = makePoint(cardID: 7, day: 1)
        let newer = makePoint(cardID: 7, day: 2)
        let (sut, loader) = makeSUT(cardID: 7)

        await load(sut, loader: loader, completingWith: .success([newer, makePoint(cardID: 8, day: 1), older]))

        #expect(sut.history == .loaded([older, newer]))
    }

    @Test func load_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.history == .failed)
    }

    @Test func load_ignoresLoadWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoading(sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success([]))

        await sut.load()
        #expect(loader.requests.count == 1)

        loader.complete(with: .success([]))
        await firstLoading.value
    }

    @Test func load_doesNotReloadLoadedHistory() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([]))
        loader.setCompletionForNewCalls(to: .success([]))

        await sut.load()

        #expect(loader.requests.count == 1)
    }

    @Test func load_retriesAfterFailure() async {
        let point = makePoint(cardID: 1, day: 1)
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .failure(anyError()))
        loader.setCompletionForNewCalls(to: .success([point]))

        await sut.load()

        #expect(sut.history == .loaded([point]))
    }

    @Test(arguments: [(CardPriceViewModel.Range.threeMonths, 90 as Int?), (.all, nil)])
    func select_reloadsHistoryOverNewRange(range: CardPriceViewModel.Range, days: Int?) async {
        let point = makePoint(cardID: 7, day: 1)
        let (sut, loader) = makeSUT(cardID: 7)
        await load(sut, loader: loader, completingWith: .success([]))
        loader.setCompletionForNewCalls(to: .success([point]))

        await sut.select(range)

        #expect(sut.range == range)
        #expect(loader.requests.last == HistoryRequest(cardIDs: [7], days: days))
        #expect(sut.history == .loaded([point]))
    }

    @Test func select_currentRangeDoesNotReload() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([]))
        loader.setCompletionForNewCalls(to: .success([]))

        await sut.select(.month)

        #expect(loader.requests.count == 1)
    }

    @Test func select_ignoresEarlierRangesHistoryArrivingLate() async {
        let monthPoint = makePoint(cardID: 1, day: 30)
        let allPoint = makePoint(cardID: 1, day: 1)
        let (sut, loader) = makeSUT()
        let loadingMonth = await startLoading(sut, loader: loader)
        let selectingAll = Task { await sut.select(.all) }
        await loader.waitForCall(at: 1)

        loader.complete(with: .success([allPoint]), at: 1)
        await selectingAll.value
        loader.complete(with: .success([monthPoint]), at: 0)
        await loadingMonth.value

        #expect(sut.range == .all)
        #expect(sut.history == .loaded([allPoint]))
    }

    // MARK: - Helpers
    private struct HistoryRequest: Equatable {
        let cardIDs: [Card.ID]
        let days: Int?
    }

    private func makeSUT(cardID: Card.ID = 1) -> (sut: CardPriceViewModel, loader: HistoryLoaderSpy) {
        let loader = HistoryLoaderSpy()
        let sut = CardPriceViewModel(cardID: cardID, loader: loader)
        return (sut, loader)
    }

    private func makePoint(cardID: Card.ID, day: Int) -> PricePoint {
        PricePoint(
            cardID: cardID,
            date: Date(timeIntervalSince1970: TimeInterval(day) * 86_400),
            price: Money(amount: Decimal(day), currencyCode: "USD")
        )
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoading(
        _ sut: CardPriceViewModel, loader: HistoryLoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.load() }
        await loader.waitForCall(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func load(
        _ sut: CardPriceViewModel, loader: HistoryLoaderSpy, completingWith result: Result<[PricePoint], Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoading(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    private final class HistoryLoaderSpy: HeldCalls<HistoryRequest, [PricePoint]>, CardPriceHistoryLoader {
        var requests: [HistoryRequest] { inputs }

        init() {
            super.init(callName: "loadPriceHistory")
        }

        func loadPriceHistory(for cardIDs: [Card.ID], days: Int?) async throws -> [PricePoint] {
            try await call(with: HistoryRequest(cardIDs: cardIDs, days: days))
        }
    }
}
