//
//  ChatComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Testing
import Networking
import os

// The stub keeps its state in a static, so run these tests one at a time.
@Suite(.serialized)
struct ChatComposerTests {

    @Test func makeChatLoader_sendsQuestionWithAPIKeyToBaseURL() async throws {
        let session = makeSession(replyingWith: makeAnswerJSON("an answer"))
        let sut = ChatComposer.makeChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        _ = try await sut.load(from: "a question")

        let requests = URLProtocolStub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/ask")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
    }

    @Test func makeChatLoader_deliversAnswerFromBackend() async throws {
        let session = makeSession(replyingWith: makeAnswerJSON("an answer"))
        let sut = ChatComposer.makeChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        let answer = try await sut.load(from: "a question")

        #expect(answer == "an answer")
    }

    @Test func makeRemoteChatLoader_sendsQuestionWithAPIKeyToBaseURL() async throws {
        let session = makeSession(replyingWith: makeAnswerJSON("an answer"))
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        _ = try await sut.load(question: "a question")

        let requests = URLProtocolStub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/ask")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
    }

    @Test func makeRemoteChatLoader_deliversAnswerWithSuggestionsFromBackend() async throws {
        let card: [String: Any] = [
            "card_id": 1,
            "name": "a card",
            "current_price": "9.99",
            "currency": "USD",
            "current_fetched_at": "2026-01-01T00:00:00+00:00",
        ]
        let session = makeSession(replyingWith: makeAnswerJSON("an answer", cards: [card]))
        let sut = ChatComposer.makeRemoteChatLoader(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        let answer = try await sut.load(question: "a question")

        #expect(answer.text == "an answer")
        #expect(answer.suggestions.map(\.card.id) == [1])
    }

    // MARK: - Helpers
    private func makeSession(replyingWith data: Data) -> URLSession {
        URLProtocolStub.reply(with: data)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private func makeAnswerJSON(_ answer: String, cards: [[String: Any]] = []) -> Data {
        try! JSONSerialization.data(withJSONObject: ["answer": answer, "cards": cards])
    }

    /// Replies 200 with the given data to every request and records the requests it saw.
    private final class URLProtocolStub: URLProtocol {
        private struct State: Sendable {
            var data = Data()
            var requests = [URLRequest]()
        }

        private static let state = OSAllocatedUnfairLock(initialState: State())

        static var requests: [URLRequest] { state.withLock { $0.requests } }

        static func reply(with data: Data) {
            state.withLock { $0 = State(data: data) }
        }

        override class func canInit(with request: URLRequest) -> Bool { true }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let request = request
            let data = Self.state.withLock { state in
                state.requests.append(request)
                return state.data
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
