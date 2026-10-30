//
//  RetryingHTTPClientTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers

struct RetryingHTTPClientTests {

    @Test func perform_deliversSuccessWithoutRetrying() async throws {
        let (sut, decoratee, sleeper) = makeSUT(results: [.success(response(200))])

        let result = try await sut.perform(anyRequest())

        #expect(result.1.statusCode == 200)
        #expect(decoratee.requests.count == 1)
        #expect(sleeper.waits.isEmpty)
    }

    @Test(arguments: [400, 401, 404, 422, 500])
    func perform_doesNotRetryStatusCodesOutsidePolicy(statusCode: Int) async throws {
        let (sut, decoratee, _) = makeSUT(results: [.success(response(statusCode)), .success(response(200))])

        let result = try await sut.perform(anyRequest())

        #expect(result.1.statusCode == statusCode)
        #expect(decoratee.requests.count == 1)
    }

    @Test(arguments: [502, 503, 504])
    func perform_retriesStatusCodesInPolicyUntilSuccess(statusCode: Int) async throws {
        let (sut, decoratee, sleeper) = makeSUT(
            results: [.success(response(statusCode)), .success(response(statusCode)), .success(response(200))],
            waits: [.seconds(1), .seconds(2), .seconds(4)]
        )

        let result = try await sut.perform(anyRequest())

        #expect(result.1.statusCode == 200)
        #expect(decoratee.requests.count == 3)
        #expect(sleeper.waits == [.seconds(1), .seconds(2)])
    }

    @Test(arguments: [URLError.Code.timedOut, .networkConnectionLost, .cannotConnectToHost])
    func perform_retriesURLErrorsInPolicyUntilSuccess(code: URLError.Code) async throws {
        let (sut, decoratee, sleeper) = makeSUT(
            results: [.failure(URLError(code)), .success(response(200))],
            waits: [.seconds(1), .seconds(2)]
        )

        let result = try await sut.perform(anyRequest())

        #expect(result.1.statusCode == 200)
        #expect(decoratee.requests.count == 2)
        #expect(sleeper.waits == [.seconds(1)])
    }

    @Test func perform_doesNotRetryErrorsOutsidePolicy() async {
        let error = anyNSError()
        let (sut, decoratee, _) = makeSUT(results: [.failure(error), .success(response(200))])

        await #expect(throws: error) {
            try await sut.perform(anyRequest())
        }
        #expect(decoratee.requests.count == 1)
    }

    @Test func perform_deliversLastResponseWhenWaitsRunOut() async throws {
        let (sut, decoratee, sleeper) = makeSUT(
            results: [.success(response(503)), .success(response(503)), .success(response(502))],
            waits: [.seconds(1), .seconds(2)]
        )

        let result = try await sut.perform(anyRequest())

        #expect(result.1.statusCode == 502)
        #expect(decoratee.requests.count == 3)
        #expect(sleeper.waits == [.seconds(1), .seconds(2)])
    }

    @Test func perform_deliversLastErrorWhenWaitsRunOut() async {
        let (sut, decoratee, _) = makeSUT(
            results: [.failure(URLError(.timedOut)), .failure(URLError(.cannotConnectToHost))],
            waits: [.seconds(1)]
        )

        await #expect(throws: URLError(.cannotConnectToHost)) {
            try await sut.perform(anyRequest())
        }
        #expect(decoratee.requests.count == 2)
    }

    @Test func perform_sendsTheSameRequestEachTry() async throws {
        let request = URLRequest(url: URL(string: "https://a-url.com/v1/search")!)
        let (sut, decoratee, _) = makeSUT(results: [.success(response(503)), .success(response(200))], waits: [.seconds(1)])

        _ = try await sut.perform(request)

        #expect(decoratee.requests == [request, request])
    }

    @Test func perform_stopsRetryingWhenCancelledWhileWaiting() async {
        let (sut, decoratee, sleeper) = makeSUT(
            results: [.success(response(503)), .success(response(200))],
            waits: [.seconds(1)]
        )
        sleeper.error = CancellationError()

        await #expect(throws: CancellationError.self) {
            try await sut.perform(anyRequest())
        }
        #expect(decoratee.requests.count == 1)
    }

    // MARK: - Helpers
    private func makeSUT(
        results: [Result<NetworkClient.URLResult, Error>],
        waits: [Duration] = [.seconds(1)]
    ) -> (sut: RetryingHTTPClient, decoratee: ScriptedClient, sleeper: SleepSpy) {
        let decoratee = ScriptedClient(results: results)
        let sleeper = SleepSpy()
        let policy = RetryPolicy(
            waits: waits,
            statusCodes: [502, 503, 504],
            errorCodes: [.timedOut, .networkConnectionLost, .cannotConnectToHost]
        )
        let sut = RetryingHTTPClient(decoratee: decoratee, policy: policy, sleep: sleeper.sleep)
        return (sut, decoratee, sleeper)
    }

    private func anyRequest() -> URLRequest {
        URLRequest(url: anyURL())
    }

    private func response(_ statusCode: Int) -> NetworkClient.URLResult {
        (Data(), httpResponse(statusCode: statusCode))
    }

    private final class ScriptedClient: NetworkClient {
        private(set) var requests = [URLRequest]()
        private var results: [Result<URLResult, Error>]

        init(results: [Result<URLResult, Error>]) {
            self.results = results
        }

        func perform(_ request: URLRequest) async throws -> URLResult {
            requests.append(request)
            return try results.removeFirst().get()
        }
    }

    private final class SleepSpy {
        private(set) var waits = [Duration]()
        var error: Error?

        func sleep(_ duration: Duration) async throws {
            waits.append(duration)
            if let error { throw error }
        }
    }
}
