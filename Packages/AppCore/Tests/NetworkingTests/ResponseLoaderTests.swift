import Testing
@testable import Networking

import Foundation

struct ChatResponseLoader: ResponseLoader {
    let url: URL
    let client: NetworkClient

    func load(from input: String) async throws -> String {
        let (data, response) = try await client.get(from: url)
        return try ChatResponseMapper.map(data, from: response)
    }
}

final class ChatResponseLoaderTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
    }

    @Test func load_requestsFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load(from: "any message")

        #expect(client.requestedURLs == [url])
    }

    @Test func loadTwice_requestsFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load(from: "any message")
        _ = try? await sut.load(from: "any message")

        #expect(client.requestedURLs == [url, url])
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
        url: URL = URL(string: "https://any-url.com")!,
        result: Result<NetworkClient.URLResult, Error> = .failure(NSError(domain: "any error", code: 0))
    ) -> (sut: ChatResponseLoader, client: SpyClient) {
        let client = SpyClient(result: result)
        let sut = ChatResponseLoader(url: url, client: client)
        return (sut, client)
    }

    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    final class SpyClient: NetworkClient {
        private(set) var requestedURLs = [URL]()
        private let result: Result<URLResult, Error>

        init(result: Result<URLResult, Error>) {
            self.result = result
        }

        func get(from url: URL) async throws -> URLResult {
            requestedURLs.append(url)
            return try result.get()
        }
    }
}
