//
//  FilteringOwnedCardSearcherTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
import Domain
@testable import Persistence
import TestHelpers

struct FilteringOwnedCardSearcherTests {

    @Test func init_doesNotLoad() {
        let (_, loader) = makeSUT()

        #expect(loader.loadCount == 0)
    }

    // Loads on every search, so the results always match what's saved.
    @Test func searchTwice_loadsOwnedCardsEachTime() async throws {
        let (sut, loader) = makeSUT()

        _ = try await sut.search("luffy")
        _ = try await sut.search("zoro")

        #expect(loader.loadCount == 2)
    }

    @Test func search_failsOnLoaderError() async {
        let loaderError = anyNSError()
        let (sut, _) = makeSUT(result: .failure(loaderError))

        await #expect(throws: loaderError) {
            try await sut.search("luffy")
        }
    }

    @Test(arguments: ["", "   ", "\n"])
    func search_deliversNothingWithoutLoadingForEmptyQuery(query: String) async throws {
        let (sut, loader) = makeSUT(result: .success([makeOwnedCard(name: "Monkey D. Luffy")]))

        let results = try await sut.search(query)

        #expect(results.isEmpty)
        #expect(loader.loadCount == 0)
    }

    @Test(arguments: ["luffy", "LUFFY", "uff", "Monkey D"])
    func search_matchesAnyPartOfNameIgnoringCase(query: String) async throws {
        let luffy = makeOwnedCard(name: "Monkey D. Luffy", number: "OP01-001")
        let (sut, _) = makeSUT(result: .success([luffy, makeOwnedCard(name: "Roronoa Zoro", number: "OP01-025")]))

        let results = try await sut.search(query)

        #expect(results == [luffy])
    }

    @Test(arguments: ["OP01-025", "op01-025", "-025"])
    func search_matchesAnyPartOfCardNumberIgnoringCase(query: String) async throws {
        let zoro = makeOwnedCard(name: "Roronoa Zoro", number: "OP01-025")
        let (sut, _) = makeSUT(result: .success([makeOwnedCard(name: "Monkey D. Luffy", number: "OP01-001"), zoro]))

        let results = try await sut.search(query)

        #expect(results == [zoro])
    }

    @Test(arguments: ["romance", "Romance Dawn", "DAWN"])
    func search_matchesAnyPartOfSetName(query: String) async throws {
        let romanceDawn = makeOwnedCard(name: "Roronoa Zoro", setName: "Romance Dawn")
        let (sut, _) = makeSUT(result: .success([romanceDawn, makeOwnedCard(name: "Nami", setName: "Paramount War")]))

        let results = try await sut.search(query)

        #expect(results == [romanceDawn])
    }

    @Test func search_matchesAnyPartOfPrinting() async throws {
        let parallel = makeOwnedCard(name: "Roronoa Zoro", printing: "Parallel")
        let (sut, _) = makeSUT(result: .success([parallel, makeOwnedCard(name: "Roronoa Zoro", printing: "Normal")]))

        let results = try await sut.search("parallel")

        #expect(results == [parallel])
    }

    @Test(arguments: ["SR", "sr"])
    func search_matchesWholeRarityIgnoringCase(query: String) async throws {
        let superRare = makeOwnedCard(name: "Roronoa Zoro", rarity: "SR")
        let (sut, _) = makeSUT(result: .success([superRare, makeOwnedCard(name: "Nami", rarity: "R")]))

        let results = try await sut.search(query)

        #expect(results == [superRare])
    }

    // Only part of a rarity, e.g. "S" of "SR" or "SEC", would match too much to be useful.
    @Test func search_doesNotMatchPartOfRarity() async throws {
        let (sut, _) = makeSUT(result: .success([makeOwnedCard(name: "Nami", rarity: "SEC")]))

        let results = try await sut.search("se")

        #expect(results.isEmpty)
    }

    // A one-letter word is in almost every name, so "l" narrows to Leaders instead of matching "Luffy".
    @Test func search_matchesOneLetterWordOnlyAsRarityOrWholeWord() async throws {
        let leader = makeOwnedCard(name: "Monkey D. Luffy", rarity: "L")
        let (sut, _) = makeSUT(result: .success([leader, makeOwnedCard(name: "Monkey D. Luffy", rarity: "SR")]))

        let results = try await sut.search("luffy l")

        #expect(results == [leader])
    }

    // Each word narrows the results, so adding words can never bring in unrelated cards.
    @Test func search_matchesOnlyCardsMatchingEveryWordInAnyValue() async throws {
        let romanceDawnLuffy = makeOwnedCard(name: "Monkey D. Luffy", setName: "Romance Dawn")
        let (sut, _) = makeSUT(result: .success([
            romanceDawnLuffy,
            makeOwnedCard(name: "Monkey D. Luffy", setName: "Paramount War"),
            makeOwnedCard(name: "Roronoa Zoro", setName: "Romance Dawn"),
        ]))

        let results = try await sut.search("luffy  romance")

        #expect(results == [romanceDawnLuffy])
    }

    @Test func search_ignoresWhitespaceAroundQuery() async throws {
        let luffy = makeOwnedCard(name: "Monkey D. Luffy")
        let (sut, _) = makeSUT(result: .success([luffy]))

        let results = try await sut.search("  luffy \n")

        #expect(results == [luffy])
    }

    // Each copy is its own owned card, so all of them are delivered, in the order they were added.
    @Test func search_deliversEveryMatchingCopyInLoaderOrder() async throws {
        let firstLuffy = makeOwnedCard(name: "Monkey D. Luffy")
        let zoro = makeOwnedCard(name: "Roronoa Zoro")
        let secondLuffy = makeOwnedCard(name: "Monkey D. Luffy")
        let (sut, _) = makeSUT(result: .success([firstLuffy, zoro, secondLuffy]))

        let results = try await sut.search("luffy")

        #expect(results == [firstLuffy, secondLuffy])
    }

    @Test func search_deliversNothingWhenNoCardMatches() async throws {
        let (sut, _) = makeSUT(result: .success([makeOwnedCard(name: "Monkey D. Luffy", number: "OP01-001")]))

        let results = try await sut.search("nami")

        #expect(results.isEmpty)
    }

    // MARK: - Helpers
    private func makeSUT(result: Result<[OwnedCard], Error> = .success([])) -> (sut: OwnedCardSearcher, loader: OwnedCardLoaderStub) {
        let loader = OwnedCardLoaderStub(result: result)
        let sut = FilteringOwnedCardSearcher(loader: loader)
        return (sut, loader)
    }

    private func makeOwnedCard(
        name: String,
        number: String? = nil,
        setName: String? = nil,
        rarity: String? = nil,
        printing: String? = nil
    ) -> OwnedCard {
        OwnedCard(card: Card(id: 1, name: name, number: number, setName: setName, rarity: rarity, printing: printing))
    }

    private final class OwnedCardLoaderStub: OwnedCardLoader {
        private(set) var loadCount = 0
        private let result: Result<[OwnedCard], Error>

        init(result: Result<[OwnedCard], Error>) {
            self.result = result
        }

        func load() async throws -> [OwnedCard] {
            loadCount += 1
            return try result.get()
        }
    }
}
