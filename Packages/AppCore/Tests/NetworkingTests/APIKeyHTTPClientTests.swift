//
//  APIKeyHTTPClientTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/20.
//

import Testing
@testable import Networking
import TestHelpers

import Foundation

final class APIKeyHTTPClientTests {

    @Test func init_doesNotRequestFromDecoratee() {
        let (_, decoratee) = makeSUT()

        #expect(decoratee.requests.isEmpty)
    }

    @Test func perform_addsAPIKeyHeader() async {
        let (sut, decoratee) = makeSUT(apiKey: "an api key")

        _ = try? await sut.perform(URLRequest(url: anyURL()))

        #expect(decoratee.requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
    }

    @Test func perform_keepsOriginalRequestDetails() async {
        var request = URLRequest(url: anyURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = anyData()
        let (sut, decoratee) = makeSUT()

        _ = try? await sut.perform(request)

        #expect(decoratee.requests.map(\.url) == [request.url])
        #expect(decoratee.requests.map(\.httpMethod) == ["POST"])
        #expect(decoratee.requests.map { $0.value(forHTTPHeaderField: "Content-Type") } == ["application/json"])
        #expect(decoratee.requests.map(\.httpBody) == [request.httpBody])
    }

    @Test func perform_deliversDecorateeError() async {
        let error = anyNSError()
        let (sut, _) = makeSUT(result: .failure(error))

        await #expect(throws: error) {
            try await sut.perform(URLRequest(url: anyURL()))
        }
    }

    @Test func perform_deliversDecorateeResult() async throws {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let (sut, _) = makeSUT(result: .success((data, response)))

        let received = try await sut.perform(URLRequest(url: anyURL()))

        #expect(received.0 == data)
        #expect(received.1 == response)
    }

    // MARK: - Helpers
    private func makeSUT(
        apiKey: String = "any api key",
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError())
    ) -> (sut: APIKeyHTTPClient, decoratee: SpyClient) {
        let decoratee = SpyClient(result: result)
        let sut = APIKeyHTTPClient(decoratee: decoratee, apiKey: apiKey)
        return (sut, decoratee)
    }

    final class SpyClient: NetworkClient {
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
}
