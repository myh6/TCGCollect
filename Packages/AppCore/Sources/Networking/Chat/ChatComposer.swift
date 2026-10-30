//
//  ChatComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation

/// Builds a chat loader for our backend.
public enum ChatComposer {
    public static func makeRemoteChatLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> ChatLoader {
        let client = BackendClient.make(apiKey: apiKey, session: session ?? makeSession())
        return RemoteLoader(
            client: client,
            makeRequest: { question in try ChatEndpoint.sendMessage(question).urlRequest(baseURL: baseURL) },
            map: ChatResponseMapper.map
        )
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        // LLM + tool calls can outlast URLSession's 60s default.
        configuration.timeoutIntervalForRequest = 120
        return URLSession(configuration: configuration)
    }
}
