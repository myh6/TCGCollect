//
//  AddToCollectionViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/24.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

// The adder spy holds adds until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct AddToCollectionViewModelTests {

    @Test func init_doesNotSaveAndShowsCardsAsNotAdded() {
        let (sut, adder) = makeSUT()

        #expect(adder.adds.isEmpty)
        #expect(sut.status(for: 1) == .notAdded)
    }

    @Test func add_addsOneCopyOfCardByDefault() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()

        await add(card, to: sut, adder: adder, completingWith: .success(()))

        #expect(adder.adds == [AddRequest(card: card, count: 1)])
    }

    @Test func add_addsChosenNumberOfCopiesInOneAdd() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        sut.incrementCopies(for: card.id)
        sut.incrementCopies(for: card.id)

        await add(card, to: sut, adder: adder, completingWith: .success(()))

        #expect(adder.adds == [AddRequest(card: card, count: 3)])
    }

    @Test func copies_isOneForCardNotChangedYet() {
        let (sut, _) = makeSUT()

        #expect(sut.copies(for: 1) == 1)
    }

    @Test func incrementCopies_addsOneUpToNine() {
        let (sut, _) = makeSUT()

        sut.incrementCopies(for: 1)
        #expect(sut.copies(for: 1) == 2)

        for _ in 0..<10 {
            sut.incrementCopies(for: 1)
        }
        #expect(sut.copies(for: 1) == 9)
    }

    @Test func decrementCopies_removesOneDownToOne() {
        let (sut, _) = makeSUT()
        sut.incrementCopies(for: 1)
        sut.incrementCopies(for: 1)

        sut.decrementCopies(for: 1)
        #expect(sut.copies(for: 1) == 2)

        sut.decrementCopies(for: 1)
        sut.decrementCopies(for: 1)
        #expect(sut.copies(for: 1) == 1)
    }

    @Test func incrementCopies_onlyChangesCopiesOfThatCard() {
        let (sut, _) = makeSUT()

        sut.incrementCopies(for: 1)

        #expect(sut.copies(for: 2) == 1)
    }

    // The count shown while saving, and once added, must stay the count that was saved.
    @Test func changingCopies_doesNothingWhileCardIsBeingAdded() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        sut.incrementCopies(for: card.id)
        let adding = await startAdding(card, to: sut, adder: adder)

        sut.incrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)
        sut.decrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)

        adder.complete(with: .success(()))
        await adding.value
    }

    @Test func changingCopies_doesNothingOnceCardIsAdded() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        sut.incrementCopies(for: card.id)
        await add(card, to: sut, adder: adder, completingWith: .success(()))

        sut.incrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)
        sut.decrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)
    }

    @Test func changingCopies_worksAgainAfterAddingFailed() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        await add(card, to: sut, adder: adder, completingWith: .failure(anyError()))

        sut.incrementCopies(for: card.id)

        #expect(sut.copies(for: card.id) == 2)
    }

    @Test func add_showsCardAsAddingWhileSaving() async {
        let (sut, adder) = makeSUT()

        let adding = await startAdding(makeCard(id: 1), to: sut, adder: adder)
        #expect(sut.status(for: 1) == .adding)

        adder.complete(with: .success(()))
        await adding.value
    }

    @Test func add_showsCardAsAddedOnSaveSuccess() async {
        let (sut, adder) = makeSUT()

        await add(makeCard(id: 1), to: sut, adder: adder, completingWith: .success(()))

        #expect(sut.status(for: 1) == .added)
    }

    @Test func add_showsCardAsFailedOnSaveFailure() async {
        let (sut, adder) = makeSUT()

        await add(makeCard(id: 1), to: sut, adder: adder, completingWith: .failure(anyError()))

        #expect(sut.status(for: 1) == .failed)
    }

    @Test func add_onlyChangesStatusOfCardBeingAdded() async {
        let (sut, adder) = makeSUT()

        let adding = await startAdding(makeCard(id: 1), to: sut, adder: adder)
        #expect(sut.status(for: 2) == .notAdded)

        adder.complete(with: .success(()))
        await adding.value
        #expect(sut.status(for: 2) == .notAdded)
    }

    // A second tap while saving mustn't add a second copy.
    @Test func add_ignoresCardAlreadyBeingAdded() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        let firstAdding = await startAdding(card, to: sut, adder: adder)
        adder.setCompletionForNewCalls(to: .success(()))

        await sut.add(card)
        #expect(adder.adds.count == 1)

        adder.complete(with: .success(()))
        await firstAdding.value
    }

    @Test func add_ignoresCardAlreadyAdded() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        await add(card, to: sut, adder: adder, completingWith: .success(()))
        adder.setCompletionForNewCalls(to: .success(()))

        await sut.add(card)

        #expect(adder.adds.count == 1)
        #expect(sut.status(for: 1) == .added)
    }

    @Test func add_retriesCardThatFailedToBeAdded() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        await add(card, to: sut, adder: adder, completingWith: .failure(anyError()))

        let retrying = await startAdding(card, to: sut, adder: adder, at: 1)
        #expect(sut.status(for: 1) == .adding)

        adder.complete(with: .success(()), at: 1)
        await retrying.value
        #expect(sut.status(for: 1) == .added)
    }

    @Test(arguments: [
        (AddToCollectionViewModel.Status.notAdded, true),
        (.adding, false),
        (.added, false),
        (.failed, true),
    ])
    func status_canAddOnlyWhenNotAddedOrFailed(status: AddToCollectionViewModel.Status, canAdd: Bool) {
        #expect(status.canAdd == canAdd)
    }

    @Test func controls_deliversCopiesAndStatusOfThatCard() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()
        sut.incrementCopies(for: card.id)
        await add(card, to: sut, adder: adder, completingWith: .success(()))

        let controls = sut.controls(for: card)
        let otherControls = sut.controls(for: makeCard(id: 2))

        #expect(controls.copies == 2)
        #expect(controls.status == .added)
        #expect(otherControls.copies == 1)
        #expect(otherControls.status == .notAdded)
    }

    @Test func controls_incrementAndDecrementCopiesOfOnlyThatCard() {
        let card = makeCard(id: 1)
        let (sut, _) = makeSUT()

        sut.controls(for: card).incrementCopies()
        sut.controls(for: card).incrementCopies()
        sut.controls(for: card).decrementCopies()

        #expect(sut.copies(for: card.id) == 2)
        #expect(sut.copies(for: 2) == 1)
    }

    @Test func controls_addAddsThatCard() async {
        let card = makeCard(id: 1)
        let (sut, adder) = makeSUT()

        sut.controls(for: card).add()
        await adder.waitForCall(at: 0)

        #expect(adder.adds.map(\.card) == [card])
        adder.complete(with: .success(()))
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: AddToCollectionViewModel, adder: AdderSpy) {
        let adder = AdderSpy()
        let sut = AddToCollectionViewModel(adder: adder)
        return (sut, adder)
    }

    private func makeCard(id: Int) -> Card {
        Card(id: id, name: "card \(id)", number: "OP01-00\(id)")
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Starts adding `card` and returns once the adder has received add number `index`, which is still waiting.
    private func startAdding(
        _ card: Card, to sut: AddToCollectionViewModel, adder: AdderSpy, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let adding = Task { await sut.add(card) }
        await adder.waitForCall(at: index, sourceLocation: sourceLocation)
        return adding
    }

    private func add(
        _ card: Card, to sut: AddToCollectionViewModel, adder: AdderSpy, completingWith result: Result<Void, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let adding = await startAdding(card, to: sut, adder: adder, sourceLocation: sourceLocation)
        adder.complete(with: result)
        await adding.value
    }

    private struct AddRequest: Equatable {
        let card: Card
        let count: Int
    }

    private final class AdderSpy: HeldCalls<AddRequest, Void>, OwnedCardAdder {
        var adds: [AddRequest] { inputs }

        init() {
            super.init(callName: "addCopies")
        }

        func addCopies(of card: Card, count: Int) async throws {
            try await call(with: AddRequest(card: card, count: count))
        }
    }
}
