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

// The saver spy holds saves until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct AddToCollectionViewModelTests {

    @Test func init_doesNotSaveAndShowsCardsAsNotAdded() {
        let (sut, saver) = makeSUT()

        #expect(saver.saves.isEmpty)
        #expect(sut.status(for: 1) == .notAdded)
    }

    @Test func add_savesOwnedCardForCard() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()

        await add(card, to: sut, saver: saver, completingWith: .success(()))

        #expect(saver.saves.map { $0.map(\.card) } == [[card]])
    }

    @Test func add_savesOneOwnedCardPerCopyInOneSave() async throws {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()
        sut.incrementCopies(for: card.id)
        sut.incrementCopies(for: card.id)

        await add(card, to: sut, saver: saver, completingWith: .success(()))

        let save = try #require(saver.saves.first)
        #expect(saver.saves.count == 1)
        #expect(save.map(\.card) == [card, card, card])
        // Each copy is its own owned card, so it can be edited or removed on its own later.
        #expect(Set(save.map(\.id)).count == 3)
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
        let (sut, saver) = makeSUT()
        sut.incrementCopies(for: card.id)
        let adding = await startAdding(card, to: sut, saver: saver)

        sut.incrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)
        sut.decrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)

        saver.complete(with: .success(()))
        await adding.value
    }

    @Test func changingCopies_doesNothingOnceCardIsAdded() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()
        sut.incrementCopies(for: card.id)
        await add(card, to: sut, saver: saver, completingWith: .success(()))

        sut.incrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)
        sut.decrementCopies(for: card.id)
        #expect(sut.copies(for: card.id) == 2)
    }

    @Test func changingCopies_worksAgainAfterAddingFailed() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()
        await add(card, to: sut, saver: saver, completingWith: .failure(anyError()))

        sut.incrementCopies(for: card.id)

        #expect(sut.copies(for: card.id) == 2)
    }

    @Test func add_showsCardAsAddingWhileSaving() async {
        let (sut, saver) = makeSUT()

        let adding = await startAdding(makeCard(id: 1), to: sut, saver: saver)
        #expect(sut.status(for: 1) == .adding)

        saver.complete(with: .success(()))
        await adding.value
    }

    @Test func add_showsCardAsAddedOnSaveSuccess() async {
        let (sut, saver) = makeSUT()

        await add(makeCard(id: 1), to: sut, saver: saver, completingWith: .success(()))

        #expect(sut.status(for: 1) == .added)
    }

    @Test func add_showsCardAsFailedOnSaveFailure() async {
        let (sut, saver) = makeSUT()

        await add(makeCard(id: 1), to: sut, saver: saver, completingWith: .failure(anyError()))

        #expect(sut.status(for: 1) == .failed)
    }

    @Test func add_onlyChangesStatusOfCardBeingAdded() async {
        let (sut, saver) = makeSUT()

        let adding = await startAdding(makeCard(id: 1), to: sut, saver: saver)
        #expect(sut.status(for: 2) == .notAdded)

        saver.complete(with: .success(()))
        await adding.value
        #expect(sut.status(for: 2) == .notAdded)
    }

    // A second tap while saving mustn't add a second copy.
    @Test func add_ignoresCardAlreadyBeingAdded() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()
        let firstAdding = await startAdding(card, to: sut, saver: saver)
        saver.setCompletionForNewCalls(to: .success(()))

        await sut.add(card)
        #expect(saver.saves.count == 1)

        saver.complete(with: .success(()))
        await firstAdding.value
    }

    @Test func add_ignoresCardAlreadyAdded() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()
        await add(card, to: sut, saver: saver, completingWith: .success(()))
        saver.setCompletionForNewCalls(to: .success(()))

        await sut.add(card)

        #expect(saver.saves.count == 1)
        #expect(sut.status(for: 1) == .added)
    }

    @Test func add_retriesCardThatFailedToBeAdded() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()
        await add(card, to: sut, saver: saver, completingWith: .failure(anyError()))

        let retrying = await startAdding(card, to: sut, saver: saver, at: 1)
        #expect(sut.status(for: 1) == .adding)

        saver.complete(with: .success(()), at: 1)
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
        let (sut, saver) = makeSUT()
        sut.incrementCopies(for: card.id)
        await add(card, to: sut, saver: saver, completingWith: .success(()))

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

    @Test func controls_addSavesThatCard() async {
        let card = makeCard(id: 1)
        let (sut, saver) = makeSUT()

        sut.controls(for: card).add()
        await saver.waitForCall(at: 0)

        #expect(saver.saves.map { $0.map(\.card) } == [[card]])
        saver.complete(with: .success(()))
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: AddToCollectionViewModel, saver: SaverSpy) {
        let saver = SaverSpy()
        let sut = AddToCollectionViewModel(saver: saver)
        return (sut, saver)
    }

    private func makeCard(id: Int) -> Card {
        Card(id: id, name: "card \(id)", number: "OP01-00\(id)")
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Starts adding `card` and returns once the saver has received save number `index`, which is still waiting.
    private func startAdding(
        _ card: Card, to sut: AddToCollectionViewModel, saver: SaverSpy, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let adding = Task { await sut.add(card) }
        await saver.waitForCall(at: index, sourceLocation: sourceLocation)
        return adding
    }

    private func add(
        _ card: Card, to sut: AddToCollectionViewModel, saver: SaverSpy, completingWith result: Result<Void, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let adding = await startAdding(card, to: sut, saver: saver, sourceLocation: sourceLocation)
        saver.complete(with: result)
        await adding.value
    }

    private final class SaverSpy: HeldCalls<[OwnedCard], Void>, OwnedCardSaver {
        var saves: [[OwnedCard]] { inputs }

        init() {
            super.init(callName: "save")
        }

        func save(_ ownedCards: [OwnedCard]) async throws {
            try await call(with: ownedCards)
        }
    }
}
