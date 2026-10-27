//
//  ChatEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/20.
//

import Foundation
import Testing
import Networking

/// Talks to a real backend; see EndToEndEnvironment for how to run it.
@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct ChatEndToEndTests {

    @Test func load_deliversAnswerWithSuggestedCardFromBackend() async throws {
        let question = "What is a Leader card in One Piece TCG?"
        // Same composition the app uses, including its real URLSession.
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: try #require(EndToEndEnvironment.baseURL), apiKey: try #require(EndToEndEnvironment.apiKey))

        let answer = try await sut.load(question: question)

        // The dev-mode answer echoes the question, which proves it went through the whole round trip.
        #expect(answer.text.contains(question))
        // Dev mode always suggests the same sample card.
        let suggestion = try #require(answer.suggestions.first)
        #expect(suggestion.card.number == "OP00-000")
        #expect(suggestion.price.price.amount == Decimal(string: "9.99"))
        #expect(suggestion.price.price.currencyCode == "USD")
    }
}
