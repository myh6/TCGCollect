//
//  RetryingHTTPClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public final class RetryingHTTPClient: NetworkClient {
    public typealias Sleep = (Duration) async throws -> Void

    private let decoratee: NetworkClient
    private let policy: RetryPolicy
    private let sleep: Sleep

    public init(decoratee: NetworkClient, policy: RetryPolicy, sleep: @escaping Sleep = { try await Task.sleep(for: $0) }) {
        self.decoratee = decoratee
        self.policy = policy
        self.sleep = sleep
    }

    public func perform(_ request: URLRequest) async throws -> URLResult {
        var waits = policy.waits[...]
        while true {
            do {
                let result = try await decoratee.perform(request)
                guard policy.retries(result.1), let wait = waits.popFirst() else { return result }
                try await sleep(wait)
            } catch let error as URLError where policy.retries(error) {
                guard let wait = waits.popFirst() else { throw error }
                try await sleep(wait)
            }
        }
    }
}
