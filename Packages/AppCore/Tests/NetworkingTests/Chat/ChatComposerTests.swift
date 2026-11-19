//
//  ChatComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Testing
import Networking
import Domain

// The stub's state is shared by the tests in this suite, so run them one at a time.
@Suite(.serialized)
struct ChatComposerTests {

    @Test func makeRemoteChatLoader_sendsQuestionWithAPIKeyToBaseURL() async throws {
        let session = Stub.makeSession(replyingWith: makeAnswerJSON("an answer"))
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        _ = try await sut.load(question: "a question", history: [])

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/ask")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["question": "a question", "history": []]])
    }

    @Test func makeRemoteChatLoader_deliversAnswerWithSuggestionsFromBackend() async throws {
        let card: [String: Any] = [
            "card_id": 1,
            "name": "a card",
            "current_price": "9.99",
            "currency": "USD",
            "current_fetched_at": "2026-01-01T00:00:00+00:00",
        ]
        let session = Stub.makeSession(replyingWith: makeAnswerJSON("an answer", cards: [card]))
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        let answer = try await sut.load(question: "a question", history: [])

        #expect(answer.text == "an answer")
        #expect(answer.suggestions.map(\.card.id) == [1])
    }

    @Test func makeRemoteChatLoader_sendsHistoryWithQuestion() async throws {
        let session = Stub.makeSession(replyingWith: makeAnswerJSON("an answer"))
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)
        let history = [ChatExchange(question: "a previous question", answer: ChatAnswer(text: "a previous answer", suggestions: []))]

        _ = try await sut.load(question: "a question", history: history)

        #expect(Stub.requestJSONBodies == [[
            "question": "a question",
            "history": [
                ["role": "user", "text": "a previous question"],
                ["role": "assistant", "text": "a previous answer"],
            ],
        ]])
    }

    // MARK: - Helpers
    private func makeAnswerJSON(_ answer: String, cards: [[String: Any]] = []) -> Data {
        try! JSONSerialization.data(withJSONObject: ["answer": answer, "cards": cards])
    }

    private final class Stub: URLProtocolStub {}
}
