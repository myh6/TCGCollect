//
//  ChatURLEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation
import Testing
@testable import Networking

struct ChatURLEndpointTests {

    @Test
    func sendMessage_endpointURL() {
        let baseURL = URL(string: "http://base-url.com")!

        let received = ChatURLEndpoint.sendMessage.url(baseURL: baseURL)

        #expect(received.absoluteString == "http://base-url.com/v1/chat")
    }

    @Test
    func sendMessage_preservesBaseURLPath() {
        let baseURL = URL(string: "http://base-url.com/staging")!

        let received = ChatURLEndpoint.sendMessage.url(baseURL: baseURL)

        #expect(received.absoluteString == "http://base-url.com/staging/v1/chat")
    }
}
