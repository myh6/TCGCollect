//
//  ChatEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation
import Testing
@testable import Networking

struct ChatEndpointTests {

    @Test
    func sendMessage_endpointURL() throws {
        let baseURL = URL(string: "http://base-url.com")!

        let received = try ChatEndpoint.sendMessage("any message").urlRequest(baseURL: baseURL)

        #expect(received.url?.absoluteString == "http://base-url.com/v1/ask")
    }

    @Test
    func sendMessage_preservesBaseURLPath() throws {
        let baseURL = URL(string: "http://base-url.com/staging")!

        let received = try ChatEndpoint.sendMessage("any message").urlRequest(baseURL: baseURL)

        #expect(received.url?.absoluteString == "http://base-url.com/staging/v1/ask")
    }

    @Test
    func sendMessage_usesPOSTMethod() throws {
        let received = try ChatEndpoint.sendMessage("any message").urlRequest(baseURL: anyBaseURL())

        #expect(received.httpMethod == "POST")
    }

    @Test
    func sendMessage_sendsJSONContentType() throws {
        let received = try ChatEndpoint.sendMessage("any message").urlRequest(baseURL: anyBaseURL())

        #expect(received.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func sendMessage_sendsMessageAsJSONQuestion() throws {
        let received = try ChatEndpoint.sendMessage("a message").urlRequest(baseURL: anyBaseURL())

        #expect(try json(received.httpBody) == ["question": "a message"])
    }

    // MARK: - Helpers
    private func anyBaseURL() -> URL {
        URL(string: "http://base-url.com")!
    }

    private func json(_ data: Data?) throws -> [String: String]? {
        guard let data else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: String]
    }
}
