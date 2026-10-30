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
        var bodies = [Data?]()
    }

    // Keyed by subclass.
    private static let states = OSAllocatedUnfairLock(initialState: [ObjectIdentifier: State]())

    /// The requests this subclass has seen since its last `makeSession(replyingWith:)`.
    class var requests: [URLRequest] {
        states.withLock { $0[ObjectIdentifier(self)]?.requests ?? [] }
    }

    /// The bodies of those requests, read from their streams, since `URLProtocol` gets bodies as streams.
    class var requestBodies: [Data?] {
        states.withLock { $0[ObjectIdentifier(self)]?.bodies ?? [] }
    }

    class var requestJSONBodies: [NSDictionary?] {
        requestBodies.map { body in body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? NSDictionary } }
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
        let body = request.httpBody ?? request.httpBodyStream.map(Self.readAll)
        let key = ObjectIdentifier(type(of: self))
        let data = Self.states.withLock { states in
            states[key, default: State()].requests.append(request)
            states[key, default: State()].bodies.append(body)
            return states[key, default: State()].data
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
