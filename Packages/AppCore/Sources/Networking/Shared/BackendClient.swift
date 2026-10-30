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
    static func make(
        apiKey: String,
        session: URLSession,
        sleep: @escaping RetryingHTTPClient.Sleep = { try await Task.sleep(for: $0) }
    ) -> NetworkClient {
        RetryingHTTPClient(
            decoratee: APIKeyHTTPClient(decoratee: URLSessionHTTPClient(session: session), apiKey: apiKey),
            policy: RetryPolicy(
                waits: .exponential(from: .seconds(1), upTo: .seconds(60)),
                statusCodes: [502, 503, 504],
                errorCodes: [.networkConnectionLost, .cannotConnectToHost]
            ),
            sleep: sleep
        )
    }
}
