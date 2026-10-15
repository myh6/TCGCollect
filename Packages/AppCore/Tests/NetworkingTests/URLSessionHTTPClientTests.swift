//
//  URLSessionHTTPClientTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Testing
@testable import Networking
import TestHelpers
import Foundation
import os

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) async throws -> NetworkClient.URLResult {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }
}

// Run test one at a time (Swift Testing runs tests in parallel by default! :o)
@Suite(.serialized)
final class URLSessionHTTPClientTests {
    private let leakTracker = MemoryLeakTracker()

    deinit {
        URLProtocolStub.removeStub()
    }

    @Test func getFromURL_performsGETRequestWithURL() async {
        let url = anyURL()
        let sut = makeSUT()

        let requests = await requestsObserved {
            _ = try? await sut.get(from: url)
        }

        #expect(requests.map(\.url) == [url])
        #expect(requests.map(\.httpMethod) == ["GET"])
    }

    //MARK: - Helpers
    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) -> URLSessionHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session)
        leakTracker.track(sut, sourceLocation: sourceLocation)
        return sut
    }

    /// Swift Testing's stand-in for an `XCTestExpectation` that hands back what it observed:
    /// runs `action`, then returns every request the stub received while it ran.
    private func requestsObserved(during action: () async -> Void) async -> [URLRequest] {
        let (stream, continuation) = AsyncStream.makeStream(of: URLRequest.self)
        URLProtocolStub.observeRequests { continuation.yield($0) }

        await action()
        continuation.finish()

        var requests = [URLRequest]()
        for await request in stream {
            requests.append(request)
        }
        return requests
    }

    private class URLProtocolStub: URLProtocol {
        private struct Stub: Sendable {
            let data: Data?
            let response: URLResponse?
            let error: Error?
            let requestObserver: (@Sendable (URLRequest) -> Void)?
        }

        private static let storage = OSAllocatedUnfairLock<Stub?>(initialState: nil)
        private static var stub: Stub? {
            get { storage.withLock { $0 } }
            set { storage.withLock { $0 = newValue } }
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error, requestObserver: nil)
        }
        
        static func removeStub() {
            stub = nil
        }
        
        static func observeRequests(observer: @Sendable @escaping (URLRequest) -> Void) {
            stub = Stub(data: nil, response: nil, error: nil, requestObserver: observer)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stub else {
                client?.urlProtocol(self, didFailWithError: URLError(.unknown))
                return
            }

            stub.requestObserver?(request)

            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else if stub.response == nil {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        override func stopLoading() {}
    }
}
