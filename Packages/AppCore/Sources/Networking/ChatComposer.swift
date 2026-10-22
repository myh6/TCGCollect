//
//  ChatComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation

/// Builds a chat loader for our backend: every request carries the API key.
public enum ChatComposer {
    public static func makeRemoteChatLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> ChatLoader {
        RemoteChatLoader(baseURL: baseURL, client: makeAuthenticatedClient(apiKey: apiKey, session: session))
    }

    /// Legacy: delivers only the answer text. Kept until the app moves to `makeRemoteChatLoader`.
    public static func makeChatLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> ResponseLoader {
        ChatResponseLoader(baseURL: baseURL, client: makeAuthenticatedClient(apiKey: apiKey, session: session))
    }

    private static func makeAuthenticatedClient(apiKey: String, session: URLSession?) -> NetworkClient {
        let client = URLSessionHTTPClient(session: session ?? makeSession())
        return APIKeyHTTPClient(decoratee: client, apiKey: apiKey)
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        // LLM + tool calls can outlast URLSession's 60s default.
        configuration.timeoutIntervalForRequest = 120
        return URLSession(configuration: configuration)
    }
}
