//
//  ChatComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Testing
import Networking

// The stub's state is shared by the tests in this suite, so run them one at a time.
@Suite(.serialized)
struct ChatComposerTests {

    @Test func makeRemoteChatLoader_sendsQuestionWithAPIKeyToBaseURL() async throws {
        let session = Stub.makeSession(replyingWith: makeAnswerJSON("an answer"))
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        _ = try await sut.load(question: "a question")

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/ask")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["question": "a question"]])
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

        let answer = try await sut.load(question: "a question")

        #expect(answer.text == "an answer")
        #expect(answer.suggestions.map(\.card.id) == [1])
    }

    // MARK: - Helpers
    private func makeAnswerJSON(_ answer: String, cards: [[String: Any]] = []) -> Data {
        try! JSONSerialization.data(withJSONObject: ["answer": answer, "cards": cards])
    }

    private final class Stub: URLProtocolStub {}
}
