//
//  RemoveFromCollectionViewModelTests.swift
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
struct RemoveFromCollectionViewModelTests {

    @Test func init_isIdleWithoutRemoving() {
        let (sut, remover) = makeSUT()

        #expect(sut.status == .idle)
        #expect(remover.removedCardIDs.isEmpty)
    }

    @Test func removeNewestCopy_removesNewestCopyOfCard() async {
        let (sut, remover) = makeSUT()

        await removeNewestCopy(of: 7, with: sut, remover: remover, completingWith: .success(()))

        #expect(remover.removedCardIDs == [7])
    }

    @Test func removeNewestCopy_isRemovingWhileWaiting() async {
        let (sut, remover) = makeSUT()

        let removing = await startRemoving(7, with: sut, remover: remover)
        #expect(sut.status == .removing)

        remover.complete(with: .success(()))
        await removing.value
    }

    @Test func removeNewestCopy_isIdleAgainOnSuccess() async {
        let (sut, remover) = makeSUT()

        await removeNewestCopy(of: 7, with: sut, remover: remover, completingWith: .success(()))

        #expect(sut.status == .idle)
    }

    @Test func removeNewestCopy_failsOnRemoverFailure() async {
        let (sut, remover) = makeSUT()

        await removeNewestCopy(of: 7, with: sut, remover: remover, completingWith: .failure(anyError()))

        #expect(sut.status == .failed)
    }

    @Test func removeNewestCopy_ignoresTapWhileRemoving() async {
        let (sut, remover) = makeSUT()
        let firstRemoving = await startRemoving(7, with: sut, remover: remover)
        remover.setCompletionForNewCalls(to: .success(()))

        await sut.removeNewestCopy(of: 7)
        #expect(remover.removedCardIDs == [7])

        remover.complete(with: .success(()))
        await firstRemoving.value
    }

    @Test func removeNewestCopy_retriesAfterFailure() async {
        let (sut, remover) = makeSUT()
        await removeNewestCopy(of: 7, with: sut, remover: remover, completingWith: .failure(anyError()))
        remover.setCompletionForNewCalls(to: .success(()))

        await sut.removeNewestCopy(of: 7)

        #expect(remover.removedCardIDs == [7, 7])
        #expect(sut.status == .idle)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: RemoveFromCollectionViewModel, remover: RemoverSpy) {
        let remover = RemoverSpy()
        let sut = RemoveFromCollectionViewModel(remover: remover)
        return (sut, remover)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startRemoving(
        _ cardID: Card.ID, with sut: RemoveFromCollectionViewModel, remover: RemoverSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let removing = Task { await sut.removeNewestCopy(of: cardID) }
        await remover.waitForCall(at: 0, sourceLocation: sourceLocation)
        return removing
    }

    private func removeNewestCopy(
        of cardID: Card.ID, with sut: RemoveFromCollectionViewModel, remover: RemoverSpy,
        completingWith result: Result<Void, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let removing = await startRemoving(cardID, with: sut, remover: remover, sourceLocation: sourceLocation)
        remover.complete(with: result)
        await removing.value
    }

    private final class RemoverSpy: HeldCalls<Card.ID, Void>, OwnedCardRemover {
        var removedCardIDs: [Card.ID] { inputs }

        init() {
            super.init(callName: "removeNewestCopy")
        }

        func removeNewestCopy(of cardID: Card.ID) async throws {
            try await call(with: cardID)
        }

        func remove(ownedCardIDs: [OwnedCard.ID]) async throws {
            Issue.record("Unexpected remove(ownedCardIDs:)")
        }
    }
}
