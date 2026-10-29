//
//  OwnedCardSaverAfterSaveDecoratorTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Testing
import AppCore
import TestHelpers

struct OwnedCardSaverAfterSaveDecoratorTests {

    @Test func init_doesNotSaveOrRunAfterSave() {
        let (_, spy) = makeSUT()

        #expect(spy.messages.isEmpty)
    }

    @Test func save_savesOwnedCardsWithDecorateeThenRunsAfterSaveOnDecorateeSuccess() async throws {
        let ownedCards = [OwnedCard(card: Card(id: 1, name: "Monkey D. Luffy")), OwnedCard(card: Card(id: 1, name: "Monkey D. Luffy"))]
        let (sut, spy) = makeSUT(saveResult: .success(()))

        try await sut.save(ownedCards)

        #expect(spy.messages == [.save(ownedCards), .afterSave])
    }

    @Test func save_deliversDecorateeErrorWithoutRunningAfterSaveOnDecorateeFailure() async {
        let saveError = anyNSError()
        let ownedCards = [OwnedCard(card: Card(id: 1, name: "Monkey D. Luffy"))]
        let (sut, spy) = makeSUT(saveResult: .failure(saveError))

        await #expect(throws: saveError) {
            try await sut.save(ownedCards)
        }
        #expect(spy.messages == [.save(ownedCards)])
    }

    // MARK: - Helpers
    private func makeSUT(saveResult: Result<Void, Error> = .success(())) -> (sut: OwnedCardSaver, spy: SaveSpy) {
        let spy = SaveSpy(saveResult: saveResult)
        let sut = OwnedCardSaverAfterSaveDecorator(decoratee: spy, afterSave: { spy.afterSave() })
        return (sut, spy)
    }

    private final class SaveSpy: OwnedCardSaver {
        enum Message: Equatable {
            case save([OwnedCard])
            case afterSave
        }

        private(set) var messages = [Message]()
        private let saveResult: Result<Void, Error>

        init(saveResult: Result<Void, Error>) {
            self.saveResult = saveResult
        }

        func save(_ ownedCards: [OwnedCard]) async throws {
            messages.append(.save(ownedCards))
            try saveResult.get()
        }

        func afterSave() {
            messages.append(.afterSave)
        }
    }
}
