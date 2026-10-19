import Testing
@testable import Networking
import TestHelpers

import Foundation

final class ChatResponseLoaderTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
    }

    @Test func load_postsToURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load(from: "any message")

        #expect(client.requestedURLs == [url])
    }

    @Test func load_postsMessageAsJSONBody() async throws {
        let (sut, client) = makeSUT()

        _ = try? await sut.load(from: "a message")

        let bodies = try client.sentBodies.map(json)
        #expect(bodies == [["message": "a message"]])
    }

    @Test func loadTwice_postsEachMessageInOrder() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load(from: "first message")
        _ = try? await sut.load(from: "second message")

        let bodies = try client.sentBodies.map(json)
        #expect(client.requestedURLs == [url, url])
        #expect(bodies == [["message": "first message"], ["message": "second message"]])
    }

    @Test func load_deliversClientErrorOnClientError() async {
        let clientError = anyNSError()
        let (sut, _) = makeSUT(result: .failure(clientError))

        await #expect(throws: clientError) {
            try await sut.load(from: "any message")
        }
    }

    @Test func load_deliversMapperErrorOnInvalidResponse() async {
        let (sut, _) = makeSUT(result: .success((Data("a message".utf8), httpResponse(statusCode: 500))))

        await #expect(throws: ChatResponseMapper.Error.invalidData) {
            try await sut.load(from: "any message")
        }
    }

    @Test func load_deliversMessageOn200HTTPResponseWithValidData() async throws {
        let (sut, _) = makeSUT(result: .success((Data("a reply".utf8), httpResponse(statusCode: 200))))

        let message = try await sut.load(from: "any message")

        #expect(message == "a reply")
    }

    // MARK: - Helpers
    private func makeSUT(
        url: URL = anyURL(),
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError())
    ) -> (sut: ChatResponseLoader, client: SpyClient) {
        let client = SpyClient(result: result)
        let sut = ChatResponseLoader(url: url, client: client)
        return (sut, client)
    }

    private func json(_ data: Data) throws -> [String: String]? {
        try JSONSerialization.jsonObject(with: data) as? [String: String]
    }

    final class SpyClient: NetworkClient {
        private var messages = [(url: URL, body: Data)]()
        private let result: Result<URLResult, Error>

        var requestedURLs: [URL] { messages.map(\.url) }
        var sentBodies: [Data] { messages.map(\.body) }

        init(result: Result<URLResult, Error>) {
            self.result = result
        }

        func get(from url: URL) async throws -> URLResult {
            Issue.record("ChatResponseLoader should post, not get")
            return try result.get()
        }

        func post(_ data: Data, to url: URL) async throws -> URLResult {
            messages.append((url, data))
            return try result.get()
        }
    }
}
