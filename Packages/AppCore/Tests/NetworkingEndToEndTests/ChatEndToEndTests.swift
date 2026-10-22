//
//  ChatEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/20.
//

import Foundation
import Testing
import Networking

/// Talks to a real backend, so it only runs when both environment variables are set, e.g.
/// `E2E_BASE_URL=http://192.168.1.113:8000 E2E_API_KEY=<DEV_API_KEY> swift test --filter NetworkingEndToEndTests`
///
/// Use the backend's DEV_API_KEY: it returns a canned answer in the real response shape
/// without calling Claude. Never commit a key value.
@Suite(.enabled(if: baseURL != nil && apiKey != nil, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct ChatEndToEndTests {

    @Test func load_deliversAnswerFromBackend() async throws {
        let question = "What is a Leader card in One Piece TCG?"
        // Same composition the app uses, including its real URLSession.
        let sut = ChatComposer.makeChatLoader(baseURL: try #require(baseURL), apiKey: try #require(apiKey))

        let answer = try await sut.load(from: question)

        // The dev-mode answer echoes the question, which proves it went through the whole round trip.
        #expect(answer.contains(question))
    }

    @Test func loadRemote_deliversAnswerWithSuggestedCardFromBackend() async throws {
        let question = "What is a Leader card in One Piece TCG?"
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: try #require(baseURL), apiKey: try #require(apiKey))

        let answer = try await sut.load(question: question)

        #expect(answer.text.contains(question))
        // Dev mode always suggests the same sample card.
        let suggestion = try #require(answer.suggestions.first)
        #expect(suggestion.card.number == "OP00-000")
        #expect(suggestion.price.price.amount == Decimal(string: "9.99"))
        #expect(suggestion.price.price.currencyCode == "USD")
    }
}

private let environment = ProcessInfo.processInfo.environment
private let baseURL = environment["E2E_BASE_URL"].flatMap(URL.init(string:))
private let apiKey = environment["E2E_API_KEY"]
