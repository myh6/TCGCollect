//
//  CatalogEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
import Networking

/// Talks to a real backend; see EndToEndEnvironment for how to run it.
/// Relies on the backend having synced Romance Dawn.
@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct CatalogEndToEndTests {
    private let romanceDawnSetID = 1100059

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
    private func makeSetPageLoader() throws -> CardSetPageLoader {
        CatalogComposer.makeRemoteCardSetPageLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
