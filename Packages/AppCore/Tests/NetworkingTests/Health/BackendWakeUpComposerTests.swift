//
//  BackendWakeUpComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking

@Suite(.serialized)
struct BackendWakeUpComposerTests {

    @Test func wakeUp_getsHealthFromBaseURL() async {
        let sut = BackendWakeUpComposer.makeBackendWakeUp(
            baseURL: URL(string: "http://base-url.com")!,
            apiKey: "an api key",
            session: Stub.makeSession(replyingWith: Data(#"{"status": "ok"}"#.utf8))
        )

        await sut.wakeUp()

        #expect(Stub.requests.map(\.url) == [URL(string: "http://base-url.com/health")!])
        #expect(Stub.requests.map(\.httpMethod) == ["GET"])
    }

    @Test func wakeUp_finishesQuietlyWhenTheBackendFails() async {
        let sut = BackendWakeUpComposer.makeBackendWakeUp(
            baseURL: URL(string: "http://base-url.com")!,
            apiKey: "an api key",
            session: Stub.makeSession(failingWith: URLError(.badServerResponse))
        )

        await sut.wakeUp()

        #expect(Stub.requests.count == 1)
    }

    // MARK: - Helpers
    private final class Stub: URLProtocolStub {}
}
