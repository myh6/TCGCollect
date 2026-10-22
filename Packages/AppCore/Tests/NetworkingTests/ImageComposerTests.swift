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
import os

// The stub keeps its state in a static, so run these tests one at a time.
@Suite(.serialized)
struct ImageComposerTests {

    // Images live on third-party hosts, so they must never receive our backend's API key.
    @Test func makeRemoteImageDataLoader_requestsImageWithoutAPIKey() async throws {
        let url = URL(string: "https://an-image-host.com/card.png")!
        let sut = ImageComposer.makeRemoteImageDataLoader(session: makeSession(replyingWith: Data("image data".utf8)))

        _ = try await sut.loadImageData(from: url)

        let requests = URLProtocolStub.requests
        #expect(requests.map(\.url) == [url])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == [nil])
    }

    @Test func makeRemoteImageDataLoader_deliversImageData() async throws {
        let imageData = Data("image data".utf8)
        let sut = ImageComposer.makeRemoteImageDataLoader(session: makeSession(replyingWith: imageData))

        let data = try await sut.loadImageData(from: URL(string: "https://an-image-host.com/card.png")!)

        #expect(data == imageData)
    }

    // MARK: - Helpers
    private func makeSession(replyingWith data: Data) -> URLSession {
        URLProtocolStub.reply(with: data)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    /// Replies 200 with the given data to every request and records the requests it saw.
    private final class URLProtocolStub: URLProtocol {
        private struct State: Sendable {
            var data = Data()
            var requests = [URLRequest]()
        }

        private static let state = OSAllocatedUnfairLock(initialState: State())

        static var requests: [URLRequest] { state.withLock { $0.requests } }

        static func reply(with data: Data) {
            state.withLock { $0 = State(data: data) }
        }

        override class func canInit(with request: URLRequest) -> Bool { true }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let request = request
            let data = Self.state.withLock { state in
                state.requests.append(request)
                return state.data
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
