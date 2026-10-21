//
//  ChatComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation

/// Builds a chat loader for our backend: every request carries the API key.
public enum ChatComposer {
    public static func makeChatLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> ResponseLoader {
        let client = URLSessionHTTPClient(session: session ?? makeSession())
        let authenticatedClient = APIKeyHTTPClient(decoratee: client, apiKey: apiKey)
        return ChatResponseLoader(baseURL: baseURL, client: authenticatedClient)
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        // LLM + tool calls can outlast URLSession's 60s default.
        configuration.timeoutIntervalForRequest = 120
        return URLSession(configuration: configuration)
    }
}
