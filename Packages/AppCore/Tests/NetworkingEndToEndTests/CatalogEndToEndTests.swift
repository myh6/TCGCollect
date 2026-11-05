//
//  CatalogEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
import Networking
import Domain

/// Talks to a real backend; see EndToEndEnvironment for how to run it.
/// Relies on the backend having synced One Piece, including Romance Dawn.
@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct CatalogEndToEndTests {
    private let onePieceSlug = "one-piece-card-game"
    private let romanceDawnSetID = 1100059

    @Test func loadGames_deliversOnePieceFromBackend() async throws {
        let games = try await makeGamesLoader().loadGames()

        #expect(games.contains(CardGame(slug: onePieceSlug, name: "One Piece Card Game")))
    }

    @Test func loadSets_deliversSetsOfTheGameNewestFirstFromBackend() async throws {
        let sets = try await makeSetsLoader().loadSets(ofGame: onePieceSlug)

        let romanceDawn = try #require(sets.first { $0.id == romanceDawnSetID })
        #expect(romanceDawn.name == "Romance Dawn")
        #expect(romanceDawn.cardCount > 0)
        let releaseDates = sets.compactMap(\.releaseDate)
        #expect(releaseDates == releaseDates.sorted(by: >))
    }

    @Test func loadSets_deliversIconOfTheSetFromBackend() async throws {
        let sets = try await makeSetsLoader().loadSets(ofGame: onePieceSlug)

        let romanceDawn = try #require(sets.first { $0.id == romanceDawnSetID })
        #expect(romanceDawn.iconURL?.scheme == "https")
    }

    @Test func loadSets_deliversCardCountMatchingTheSetsCards() async throws {
        let sets = try await makeSetsLoader().loadSets(ofGame: onePieceSlug)
        let romanceDawn = try #require(sets.first { $0.id == romanceDawnSetID })

        let page = try await makeSetPageLoader().loadCards(inSet: romanceDawnSetID, offset: 0)

        #expect(page.totalCount == romanceDawn.cardCount)
    }

    @Test func loadCards_deliversFirstPageOfCardsInTheSetFromBackend() async throws {
        let page = try await makeSetPageLoader().loadCards(inSet: romanceDawnSetID, offset: 0)

        #expect(page.cards.count == 50)
        #expect(page.cards.allSatisfy { $0.card.setID == romanceDawnSetID })
        #expect(page.totalCount > page.cards.count)
    }

    @Test func loadCards_deliversNextPageWithoutRepeatingCards() async throws {
        let sut = try makeSetPageLoader()

        let first = try await sut.loadCards(inSet: romanceDawnSetID, offset: 0)
        let second = try await sut.loadCards(inSet: romanceDawnSetID, offset: first.cards.count)

        #expect(!second.cards.isEmpty)
        #expect(Set(first.cards.map(\.card.id)).isDisjoint(with: second.cards.map(\.card.id)))
    }

    // MARK: - Helpers
    private func makeGamesLoader() throws -> CardGamesLoader {
        CatalogComposer.makeRemoteCardGamesLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }

    private func makeSetsLoader() throws -> CardSetsLoader {
        CatalogComposer.makeRemoteCardSetsLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }

    private func makeSetPageLoader() throws -> CardSetPageLoader {
        CatalogComposer.makeRemoteCardSetPageLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
