//
//  RemoteLoaderTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking
import TestHelpers

struct RemoteLoaderTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requests.isEmpty)
    }

    @Test func load_sendsRequestMadeFromInput() async {
        let (sut, client) = makeSUT()

        _ = try? await sut.load("an input")

        #expect(client.requests == [request(for: "an input")])
    }

    @Test func loadTwice_sendsEachRequestInOrder() async {
        let (sut, client) = makeSUT()

        _ = try? await sut.load("first")
        _ = try? await sut.load("second")

        #expect(client.requests == [request(for: "first"), request(for: "second")])
    }

    @Test func load_deliversMakeRequestErrorWithoutRequesting() async {
        let makeRequestError = anyNSError()
        let (sut, client) = makeSUT(makeRequest: { _ in throw makeRequestError })

        await #expect(throws: makeRequestError) {
            try await sut.load("an input")
        }
        #expect(client.requests.isEmpty)
    }

    @Test func load_deliversClientErrorWithoutMapping() async {
        let clientError = anyNSError()
        var mapCallCount = 0
        let (sut, _) = makeSUT(result: .failure(clientError), map: { _, _ in
            mapCallCount += 1
            return "a resource"
        })

        await #expect(throws: clientError) {
            try await sut.load("an input")
        }
        #expect(mapCallCount == 0)
    }

    @Test func load_mapsClientDataAndResponse() async throws {
        let data = Data("some data".utf8)
        let response = httpResponse(statusCode: 201)
        var mapped = [(Data, HTTPURLResponse)]()
        let (sut, _) = makeSUT(result: .success((data, response)), map: { data, response in
            mapped.append((data, response))
            return "a resource"
        })

        _ = try await sut.load("an input")

        #expect(mapped.map(\.0) == [data])
        #expect(mapped.map(\.1) == [response])
    }

    @Test func load_deliversMapperError() async {
        let mapperError = anyNSError()
        let (sut, _) = makeSUT(result: .success(anyResult()), map: { _, _ in throw mapperError })

        await #expect(throws: mapperError) {
            try await sut.load("an input")
        }
    }

    @Test func load_deliversMappedResource() async throws {
        let (sut, _) = makeSUT(result: .success(anyResult()), map: { _, _ in "a resource" })

        let resource = try await sut.load("an input")

        #expect(resource == "a resource")
    }

    // MARK: - Helpers
    private func makeSUT(
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError()),
        makeRequest: @escaping RemoteLoader<String, String>.MakeRequest = { request(for: $0) },
        map: @escaping RemoteLoader<String, String>.Map = { _, _ in "any resource" }
    ) -> (sut: RemoteLoader<String, String>, client: NetworkClientSpy) {
        let client = NetworkClientSpy(result: result)
        let sut = RemoteLoader(client: client, makeRequest: makeRequest, map: map)
        return (sut, client)
    }

    private func anyResult() -> NetworkClient.URLResult {
        (Data("any data".utf8), httpResponse(statusCode: 200))
    }
}

private func request(for input: String) -> URLRequest {
    URLRequest(url: URL(string: "https://a-url.com/\(input)")!)
}
