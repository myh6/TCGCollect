//
//  ChatEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation
import Testing
@testable import Networking
import Domain

// URL, method and content type are checked for every endpoint in BackendEndpointTests.
struct ChatEndpointTests {

    @Test
    func sendMessage_sendsMessageAsJSONQuestionWithEmptyHistory() throws {
        let received = try ChatEndpoint.sendMessage("a message", history: []).urlRequest(baseURL: anyBaseURL())

        #expect(try json(received.httpBody) == ["question": "a message", "history": []])
    }

    @Test
    func sendMessage_sendsEachPreviousExchangeAsUserThenAssistantTextInOrder() throws {
        let history = [
            ChatExchange(question: "a question", answer: ChatAnswer(text: "an answer", suggestions: [])),
            ChatExchange(question: "another question", answer: ChatAnswer(text: "another answer", suggestions: [])),
        ]

        let received = try ChatEndpoint.sendMessage("a message", history: history).urlRequest(baseURL: anyBaseURL())

        #expect(try json(received.httpBody) == [
            "question": "a message",
            "history": [
                ["role": "user", "text": "a question"],
                ["role": "assistant", "text": "an answer"],
                ["role": "user", "text": "another question"],
                ["role": "assistant", "text": "another answer"],
            ],
        ])
    }

    // MARK: - Helpers
    private func anyBaseURL() -> URL {
        URL(string: "http://base-url.com")!
    }

    private func json(_ data: Data?) throws -> NSDictionary? {
        guard let data else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? NSDictionary
    }
}
