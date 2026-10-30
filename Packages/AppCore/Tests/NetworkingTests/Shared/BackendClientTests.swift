//
//  BackendClientTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers

@Suite(.serialized)
struct BackendClientTests {

    @Test func make_retriesWhileTheServerWakesUp() async throws {
        let sleeper = SleepSpy()
        let sut = makeSUT(statusCodes: [503, 503, 200], sleeper: sleeper)

        let result = try await sut.perform(URLRequest(url: anyURL()))

        #expect(result.1.statusCode == 200)
        #expect(Stub.requests.count == 3)
        #expect(Stub.requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == Array(repeating: "an api key", count: 3))
        #expect(sleeper.waits == [.seconds(1), .seconds(2)])
    }

    @Test func make_givesUpAfterWaitingAboutAMinute() async throws {
        let sleeper = SleepSpy()
        let sut = makeSUT(statusCodes: [503], sleeper: sleeper)

        let result = try await sut.perform(URLRequest(url: anyURL()))

        #expect(result.1.statusCode == 503)
        #expect(sleeper.waits == sleeper.waits.sorted())
        #expect(sleeper.waits.reduce(.zero, +) == .seconds(60))
    }

    @Test func make_doesNotRetryRejectedRequests() async throws {
        let sleeper = SleepSpy()
        let sut = makeSUT(statusCodes: [401], sleeper: sleeper)

        let result = try await sut.perform(URLRequest(url: anyURL()))

        #expect(result.1.statusCode == 401)
        #expect(Stub.requests.count == 1)
        #expect(sleeper.waits.isEmpty)
    }

    @Test func make_retriesLostConnections() async {
        let sleeper = SleepSpy()
        let sut = BackendClient.make(apiKey: "an api key", session: Stub.makeSession(failingWith: URLError(.networkConnectionLost)), sleep: sleeper.sleep)

        await #expect(throws: URLError.self) {
            try await sut.perform(URLRequest(url: anyURL()))
        }
        #expect(sleeper.waits.reduce(.zero, +) == .seconds(60))
    }

    @Test func make_doesNotRetryTimeouts() async {
        let sleeper = SleepSpy()
        let sut = BackendClient.make(apiKey: "an api key", session: Stub.makeSession(failingWith: URLError(.timedOut)), sleep: sleeper.sleep)

        await #expect(throws: URLError.self) {
            try await sut.perform(URLRequest(url: anyURL()))
        }
        #expect(Stub.requests.count == 1)
        #expect(sleeper.waits.isEmpty)
    }

    // MARK: - Helpers
    private func makeSUT(statusCodes: [Int], sleeper: SleepSpy) -> NetworkClient {
        BackendClient.make(
            apiKey: "an api key",
            session: Stub.makeSession(replyingWith: Data(), statusCodes: statusCodes),
            sleep: sleeper.sleep
        )
    }

    private final class SleepSpy {
        private(set) var waits = [Duration]()

        func sleep(_ duration: Duration) async throws {
            waits.append(duration)
        }
    }

    private final class Stub: URLProtocolStub {}
}
