//
//  CatalogUIComposerTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
struct CatalogUIComposerTests {

    @Test func gamesList_deliversGamesFromLoader() async {
        let games = [CardGame(slug: "a-game", name: "A Game")]
        let sut = CatalogUIComposer.makeGamesList(loader: CatalogLoaderStub(games: games))

        await sut.load()

        #expect(sut.items == .loaded(games))
    }

    @Test func setsList_loadsSetsOfTheGame() async {
        let loader = CatalogLoaderStub(sets: [])
        let sut = CatalogUIComposer.makeSetsList(of: CardGame(slug: "a-game", name: "A Game"), loader: loader)

        await sut.load()

        #expect(loader.requestedGameSlugs == ["a-game"])
    }

    @Test func setsList_deliversSetsFromLoader() async {
        let sets = [CardSet(id: 1, name: "a set", cardCount: 1, releaseDate: nil, iconURL: nil)]
        let sut = CatalogUIComposer.makeSetsList(of: CardGame(slug: "a-game", name: "A Game"), loader: CatalogLoaderStub(sets: sets))

        await sut.load()

        #expect(sut.items == .loaded(sets))
    }

    // MARK: - Helpers
    @MainActor
    private final class CatalogLoaderStub: CardGamesLoader, CardSetsLoader {
        private(set) var requestedGameSlugs = [String]()
        private let games: [CardGame]
        private let sets: [CardSet]

        init(games: [CardGame] = [], sets: [CardSet] = []) {
            self.games = games
            self.sets = sets
        }

        func loadGames() async throws -> [CardGame] {
            games
        }

        func loadSets(ofGame gameSlug: String) async throws -> [CardSet] {
            requestedGameSlugs.append(gameSlug)
            return sets
        }
    }
}
