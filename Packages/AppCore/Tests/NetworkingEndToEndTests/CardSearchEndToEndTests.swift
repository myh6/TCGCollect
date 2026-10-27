//
//  CardSearchEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
import Networking

/// Talks to a real backend; see EndToEndEnvironment for how to run it.
/// Search reads the backend's real card catalogue, so these only rely on a Luffy card being in it.
@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct CardSearchEndToEndTests {

    @Test func search_deliversCardsMatchingTheQueryFromBackend() async throws {
        let results = try await makeSUT().search("luffy")

        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.card.name.localizedCaseInsensitiveContains("luffy") })
    }

    @Test func search_deliversNoResultsForAQueryMatchingNoCard() async throws {
        let results = try await makeSUT().search("zzzz-no-such-card-zzzz")

        #expect(results.isEmpty)
    }

    // MARK: - Helpers
    /// Same composition the app uses, including its real URLSession.
    private func makeSUT() throws -> CardSearcher {
        CardSearchComposer.makeRemoteCardSearcher(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
