//
//  ImageComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Foundation
import Testing
import Networking
import Domain

// The stub's state is shared by the tests in this suite, so run them one at a time.
@Suite(.serialized)
struct ImageComposerTests {

    // Images live on third-party hosts, so they must never receive our backend's API key.
    @Test func makeRemoteImageDataLoader_requestsImageWithoutAPIKey() async throws {
        let url = URL(string: "https://an-image-host.com/card.png")!
        let sut = ImageComposer.makeRemoteImageDataLoader(session: Stub.makeSession(replyingWith: Data("image data".utf8)))

        _ = try await sut.loadImageData(from: url)

        let requests = Stub.requests
        #expect(requests.map(\.url) == [url])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == [nil])
    }

    @Test func makeRemoteImageDataLoader_deliversImageData() async throws {
        let imageData = Data("image data".utf8)
        let sut = ImageComposer.makeRemoteImageDataLoader(session: Stub.makeSession(replyingWith: imageData))

        let data = try await sut.loadImageData(from: URL(string: "https://an-image-host.com/card.png")!)

        #expect(data == imageData)
    }

    // MARK: - Helpers
    private final class Stub: URLProtocolStub {}
}
