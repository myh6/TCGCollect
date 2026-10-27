//
//  BackendClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation

/// The client for our own backend: every request carries the API key.
/// Not for third-party hosts such as image servers, which must never see the key.
enum BackendClient {
    static func make(apiKey: String, session: URLSession) -> NetworkClient {
        APIKeyHTTPClient(decoratee: URLSessionHTTPClient(session: session), apiKey: apiKey)
    }
}
