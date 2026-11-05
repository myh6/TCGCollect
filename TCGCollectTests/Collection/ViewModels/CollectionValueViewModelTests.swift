//
//  CollectionValueViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CollectionValueViewModelTests {

    @Test func init_startsIdleOnOneMonthWithoutLoading() {
        let (sut, loader) = makeSUT()

        #expect(sut.valueHistory == .idle)
        #expect(sut.range == .month)
        #expect(loader.requests.isEmpty)
    }

    @Test func load_requestsEachOwnedCardsQuantityOverOneMonth() async {
        let (sut, loader) = makeSUT()

        await load(sut, owned(zoro, luffy, luffy), loader: loader, completingWith: .success(anyHistory()))

        #expect(loader.requests == [ValueRequest(quantities: [luffy.id: 2, zoro.id: 1], days: 30)])
    }

    @Test func load_deliversNoValueWithoutRequestingWhenNothingIsOwned() async {
        let (sut, loader) = makeSUT()

        await sut.load([])

        #expect(sut.valueHistory == .loaded(CollectionValueHistory(currentTotal: nil, points: [])))
        #expect(loader.requests.isEmpty)
    }

    @Test func load_isLoadingWhileWaitingForValueHistory() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoading(sut, owned(luffy), loader: loader)
        #expect(sut.valueHistory == .loading)

        loader.complete(with: .success(anyHistory()))
        await loading.value
    }

    @Test func load_deliversLoadedValueHistory() async {
        let history = makeHistory(dollars: 20)
        let (sut, loader) = makeSUT()

        await load(sut, owned(luffy), loader: loader, completingWith: .success(history))

        #expect(sut.valueHistory == .loaded(history))
    }

    @Test func load_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await load(sut, owned(luffy), loader: loader, completingWith: .failure(anyError()))

        #expect(sut.valueHistory == .failed)
    }

    @Test func load_ignoresSameCardsWhileLoading() async {
        let cards = owned(luffy)
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoading(sut, cards, loader: loader)
        loader.setCompletionForNewCalls(to: .success(anyHistory()))

        await sut.load(cards)
        #expect(loader.requests.count == 1)

        loader.complete(with: .success(anyHistory()))
        await firstLoading.value
    }

    @Test func load_doesNotReloadSameCards() async {
        let cards = owned(luffy)
        let (sut, loader) = makeSUT()
        await load(sut, cards, loader: loader, completingWith: .success(anyHistory()))
        loader.setCompletionForNewCalls(to: .success(anyHistory()))

        await sut.load(cards)

        #expect(loader.requests.count == 1)
    }

    @Test func load_reloadsWhenOwnedCardsChange() async {
        let (sut, loader) = makeSUT()
        await load(sut, owned(luffy), loader: loader, completingWith: .success(anyHistory()))
        loader.setCompletionForNewCalls(to: .success(anyHistory()))

        await sut.load(owned(luffy, zoro))

        #expect(loader.requests.last == ValueRequest(quantities: [luffy.id: 1, zoro.id: 1], days: 30))
    }

    @Test func load_retriesAfterFailure() async {
        let cards = owned(luffy)
        let history = makeHistory(dollars: 10)
        let (sut, loader) = makeSUT()
        await load(sut, cards, loader: loader, completingWith: .failure(anyError()))
        loader.setCompletionForNewCalls(to: .success(history))

        await sut.load(cards)

        #expect(sut.valueHistory == .loaded(history))
    }

    @Test(arguments: [(CollectionValueViewModel.Range.week, 7), (.threeMonths, 90)])
    func select_reloadsValueHistoryOverNewRange(range: CollectionValueViewModel.Range, days: Int) async {
        let history = makeHistory(dollars: 10)
        let (sut, loader) = makeSUT()
        await load(sut, owned(luffy), loader: loader, completingWith: .success(anyHistory()))
        loader.setCompletionForNewCalls(to: .success(history))

        await sut.select(range)

        #expect(sut.range == range)
        #expect(loader.requests.last == ValueRequest(quantities: [luffy.id: 1], days: days))
        #expect(sut.valueHistory == .loaded(history))
    }

    @Test func select_currentRangeDoesNotReload() async {
        let (sut, loader) = makeSUT()
        await load(sut, owned(luffy), loader: loader, completingWith: .success(anyHistory()))
        loader.setCompletionForNewCalls(to: .success(anyHistory()))

        await sut.select(.month)

        #expect(loader.requests.count == 1)
    }

    @Test func select_ignoresEarlierRangesValueHistoryArrivingLate() async {
        let monthHistory = makeHistory(dollars: 10)
        let weekHistory = makeHistory(dollars: 12)
        let (sut, loader) = makeSUT()
        let loadingMonth = await startLoading(sut, owned(luffy), loader: loader)
        let selectingWeek = Task { await sut.select(.week) }
        await loader.waitForCall(at: 1)

        loader.complete(with: .success(weekHistory), at: 1)
        await selectingWeek.value
        loader.complete(with: .success(monthHistory), at: 0)
        await loadingMonth.value

        #expect(sut.range == .week)
        #expect(sut.valueHistory == .loaded(weekHistory))
    }

    @Test func load_keepsShowingValueWhileReloadingForChangedCards() async {
        let before = makeHistory(dollars: 10)
        let after = makeHistory(dollars: 4)
        let (sut, loader) = makeSUT()
        await load(sut, owned(luffy, zoro), loader: loader, completingWith: .success(before))

        let reloading = Task { await sut.load(owned(luffy)) }
        await loader.waitForCall(at: 1)
        #expect(sut.valueHistory == .loaded(before))
        #expect(sut.isReloading)

        loader.complete(with: .success(after), at: 1)
        await reloading.value
        #expect(sut.valueHistory == .loaded(after))
        #expect(!sut.isReloading)
    }

    @Test func select_keepsShowingValueWhileLoadingNewRange() async {
        let monthHistory = makeHistory(dollars: 10)
        let (sut, loader) = makeSUT()
        await load(sut, owned(luffy), loader: loader, completingWith: .success(monthHistory))

        let selecting = Task { await sut.select(.week) }
        await loader.waitForCall(at: 1)
        #expect(sut.valueHistory == .loaded(monthHistory))
        #expect(sut.isReloading)

        loader.complete(with: .success(anyHistory()), at: 1)
        await selecting.value
        #expect(!sut.isReloading)
    }

    @Test func load_failsWhenReloadFails() async {
        let (sut, loader) = makeSUT()
        await load(sut, owned(luffy, zoro), loader: loader, completingWith: .success(makeHistory(dollars: 10)))
        loader.setCompletionForNewCalls(to: .failure(anyError()))

        await sut.load(owned(luffy))

        #expect(sut.valueHistory == .failed)
        #expect(!sut.isReloading)
    }

    @Test func load_isNotReloadingDuringFirstLoad() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoading(sut, owned(luffy), loader: loader)
        #expect(!sut.isReloading)

        loader.complete(with: .success(anyHistory()))
        await loading.value
    }

    // MARK: - Helpers
    private struct ValueRequest: Equatable {
        let quantities: [Card.ID: Int]
        let days: Int?
    }

    private let luffy = Card(id: 1, name: "Monkey.D.Luffy")
    private let zoro = Card(id: 2, name: "Roronoa Zoro")

    private func makeSUT() -> (sut: CollectionValueViewModel, loader: ValueHistoryLoaderSpy) {
        let loader = ValueHistoryLoaderSpy()
        let sut = CollectionValueViewModel(loader: loader)
        return (sut, loader)
    }

    private func owned(_ cards: Card...) -> [OwnedCard] {
        cards.map { OwnedCard(card: $0) }
    }

    private func makeHistory(dollars amount: Decimal) -> CollectionValueHistory {
        let value = Money(amount: amount, currencyCode: "USD")
        return CollectionValueHistory(currentTotal: value, points: [CollectionValuePoint(date: Date(timeIntervalSince1970: 86_400), value: value)])
    }

    private func anyHistory() -> CollectionValueHistory {
        CollectionValueHistory(currentTotal: nil, points: [])
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoading(
        _ sut: CollectionValueViewModel, _ ownedCards: [OwnedCard], loader: ValueHistoryLoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.load(ownedCards) }
        await loader.waitForCall(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func load(
        _ sut: CollectionValueViewModel, _ ownedCards: [OwnedCard], loader: ValueHistoryLoaderSpy,
        completingWith result: Result<CollectionValueHistory, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoading(sut, ownedCards, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    private final class ValueHistoryLoaderSpy: HeldCalls<ValueRequest, CollectionValueHistory>, CollectionValueHistoryLoader {
        var requests: [ValueRequest] { inputs }

        init() {
            super.init(callName: "loadValueHistory")
        }

        func loadValueHistory(of quantities: [Card.ID: Int], days: Int?) async throws -> CollectionValueHistory {
            try await call(with: ValueRequest(quantities: quantities, days: days))
        }
    }
}
