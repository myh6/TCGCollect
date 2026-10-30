//
//  BackendWakeUp.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public struct BackendWakeUp {
    private let baseURL: URL
    private let client: NetworkClient

    init(baseURL: URL, client: NetworkClient) {
        self.baseURL = baseURL
        self.client = client
    }

    public func wakeUp() async {
        _ = try? await client.perform(HealthEndpoint.check.urlRequest(baseURL: baseURL))
    }
}

public enum BackendWakeUpComposer {
    public static func makeBackendWakeUp(baseURL: URL, apiKey: String, session: URLSession? = nil) -> BackendWakeUp {
        BackendWakeUp(
            baseURL: baseURL,
            client: BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
        )
    }
}
