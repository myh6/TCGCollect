//
//  NetworkClientSpy.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Networking

/// Records every request and answers each one with the same result.
final class NetworkClientSpy: NetworkClient {
    private(set) var requests = [URLRequest]()
    private let result: Result<URLResult, Error>

    init(result: Result<URLResult, Error>) {
        self.result = result
    }

    func perform(_ request: URLRequest) async throws -> URLResult {
        requests.append(request)
        return try result.get()
    }
}
