//
//  CardDetailsComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking
import Domain

@Suite(.serialized)
struct CardDetailsComposerTests {

    @Test func makeRemoteCardDetailsLoader_sendsCardIDWithAPIKeyToBaseURL() async throws {
        let sut = makeSUT(replyingWith: makeResponseJSON(details: nil))

        _ = try await sut.loadDetails(for: 675180)

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/cards/details")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["card_id": 675180]])
    }

    @Test func makeRemoteCardDetailsLoader_deliversDetailsFromBackend() async throws {
        let sut = makeSUT(replyingWith: makeResponseJSON(details: ["cardType": ["Event"], "color": ["Red"]]))

        let details = try await sut.loadDetails(for: 1)

        #expect(details == .onePiece(OnePieceDetails(category: .event, colors: [.red])))
    }

    @Test func makeRemoteCardDetailsLoader_deliversNoDetailsWhenBackendHasNone() async throws {
        let sut = makeSUT(replyingWith: makeResponseJSON(details: nil))

        let details = try await sut.loadDetails(for: 1)

        #expect(details == nil)
    }

    // MARK: - Helpers
    private func makeSUT(replyingWith data: Data) -> CardDetailsLoader {
        CardDetailsComposer.makeRemoteCardDetailsLoader(
            baseURL: URL(string: "http://base-url.com")!,
            apiKey: "an api key",
            session: Stub.makeSession(replyingWith: data)
        )
    }

    private func makeResponseJSON(details: [String: Any]?) -> Data {
        try! JSONSerialization.data(withJSONObject: ["card_id": 1, "details": details.map { $0 as Any } ?? NSNull()])
    }

    private final class Stub: URLProtocolStub {}
}
