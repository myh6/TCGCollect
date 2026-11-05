//
//  CollectionEditViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/05.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CollectionEditViewModelTests {

    @Test func init_isNotEditingAndRemovesNothing() {
        let (sut, remover) = makeSUT()

        #expect(!sut.isEditing)
        #expect(sut.removingCopies.isEmpty)
        #expect(sut.failedCopy == nil)
        #expect(remover.removals.isEmpty)
    }

    @Test func startEditing_startsEditing() {
        let (sut, _) = makeSUT()

        sut.startEditing()

        #expect(sut.isEditing)
    }

    @Test func stopEditing_stopsEditing() {
        let (sut, _) = makeSUT()
        sut.startEditing()

        sut.stopEditing()

        #expect(!sut.isEditing)
    }

    @Test func remove_removesThatCopyFromCollection() async {
        let copy = UUID()
        let (sut, remover) = makeSUT()

        await remove(copy, with: sut, remover: remover, completingWith: .success(()))

        #expect(remover.removals == [[copy]])
    }

    @Test func remove_marksCopyAsRemovingUntilDone() async {
        let copy = UUID()
        let (sut, remover) = makeSUT()

        let removing = await startRemoving(copy, with: sut, remover: remover)
        #expect(sut.removingCopies == [copy])

        remover.complete(with: .success(()))
        await removing.value
        #expect(sut.removingCopies.isEmpty)
    }

    @Test func remove_ignoresSecondTapOnCopyBeingRemoved() async {
        let copy = UUID()
        let (sut, remover) = makeSUT()
        let removing = await startRemoving(copy, with: sut, remover: remover)
        remover.setCompletionForNewCalls(to: .success(()))

        await sut.remove(copy)
        #expect(remover.removals == [[copy]])

        remover.complete(with: .success(()))
        await removing.value
    }

    @Test func remove_removesAnotherCopyWhileFirstIsStillBeingRemoved() async {
        let first = UUID()
        let second = UUID()
        let (sut, remover) = makeSUT()
        let removingFirst = await startRemoving(first, with: sut, remover: remover)

        let removingSecond = Task { await sut.remove(second) }
        await remover.waitForCall(at: 1)
        #expect(sut.removingCopies == [first, second])

        remover.complete(with: .success(()), at: 1)
        remover.complete(with: .success(()), at: 0)
        await removingSecond.value
        await removingFirst.value
        #expect(remover.removals == [[first], [second]])
    }

    @Test func remove_marksCopyAsFailedOnRemoverFailure() async {
        let copy = UUID()
        let (sut, remover) = makeSUT()

        await remove(copy, with: sut, remover: remover, completingWith: .failure(anyError()))

        #expect(sut.failedCopy == copy)
        #expect(sut.removingCopies.isEmpty)
    }

    @Test func remove_clearsEarlierFailureWhenRemovingAgain() async {
        let copy = UUID()
        let (sut, remover) = makeSUT()
        await remove(copy, with: sut, remover: remover, completingWith: .failure(anyError()))
        remover.setCompletionForNewCalls(to: .success(()))

        await sut.remove(copy)

        #expect(sut.failedCopy == nil)
    }

    @Test func stopEditing_clearsFailure() async {
        let copy = UUID()
        let (sut, remover) = makeSUT()
        sut.startEditing()
        await remove(copy, with: sut, remover: remover, completingWith: .failure(anyError()))

        sut.stopEditing()

        #expect(sut.failedCopy == nil)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: CollectionEditViewModel, remover: RemoverSpy) {
        let remover = RemoverSpy()
        let sut = CollectionEditViewModel(remover: remover)
        return (sut, remover)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startRemoving(
        _ copy: OwnedCard.ID, with sut: CollectionEditViewModel, remover: RemoverSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let removing = Task { await sut.remove(copy) }
        await remover.waitForCall(at: 0, sourceLocation: sourceLocation)
        return removing
    }

    private func remove(
        _ copy: OwnedCard.ID, with sut: CollectionEditViewModel, remover: RemoverSpy,
        completingWith result: Result<Void, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let removing = await startRemoving(copy, with: sut, remover: remover, sourceLocation: sourceLocation)
        remover.complete(with: result)
        await removing.value
    }

    private final class RemoverSpy: HeldCalls<[OwnedCard.ID], Void>, OwnedCardRemover {
        var removals: [[OwnedCard.ID]] { inputs }

        init() {
            super.init(callName: "remove")
        }

        func remove(ownedCardIDs: [OwnedCard.ID]) async throws {
            try await call(with: ownedCardIDs)
        }

        func removeNewestCopy(of cardID: Card.ID) async throws {
            Issue.record("Unexpected removeNewestCopy(of:)")
        }
    }
}
