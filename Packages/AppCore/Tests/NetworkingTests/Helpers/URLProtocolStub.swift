//
//  URLProtocolStub.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import os

/// Replies 200 with the given data to every request and records the requests it saw.
///
/// Declare one subclass per test suite, e.g. `private final class Stub: URLProtocolStub {}`:
/// each subclass keeps its own state, so suites running in parallel don't see each other's
/// replies or requests. Within a suite the state is shared, so mark the suite `.serialized`.
class URLProtocolStub: URLProtocol {
    private struct State: Sendable {
        var data = Data()
        var requests = [URLRequest]()
    }

    // Keyed by subclass.
    private static let states = OSAllocatedUnfairLock(initialState: [ObjectIdentifier: State]())

    /// The requests this subclass has seen since its last `makeSession(replyingWith:)`.
    class var requests: [URLRequest] {
        states.withLock { $0[ObjectIdentifier(self)]?.requests ?? [] }
    }

    /// Clears what this subclass recorded and returns a session whose requests it answers with `data`.
    class func makeSession(replyingWith data: Data) -> URLSession {
        states.withLock { $0[ObjectIdentifier(self)] = State(data: data) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let request = request
        let key = ObjectIdentifier(type(of: self))
        let data = Self.states.withLock { states in
            states[key, default: State()].requests.append(request)
            return states[key, default: State()].data
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
