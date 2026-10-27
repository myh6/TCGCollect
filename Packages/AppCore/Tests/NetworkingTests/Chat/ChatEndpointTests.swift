//
//  ChatEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation
import Testing
@testable import Networking

// URL, method and content type are checked for every endpoint in BackendEndpointTests.
struct ChatEndpointTests {

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
