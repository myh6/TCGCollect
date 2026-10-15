import Testing
@testable import Networking

import Foundation

struct ChatResponseLoader: ResponseLoader {
    enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }

    let url: URL
    let client: NetworkClient

    func load(from input: String) async throws -> String {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let message = String(data: data, encoding: .utf8) else {
            throw Error.invalidData
        }
        return message
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

    @Test func load_deliversConnectivityErrorOnClientError() async {
        let (sut, _) = makeSUT(result: .failure(anyNSError()))

        await #expect(throws: ChatResponseLoader.Error.connectivity) {
            try await sut.load(from: "any message")
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func load_deliversInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) async {
        let (sut, _) = makeSUT(result: .success((Data("a message".utf8), httpResponse(statusCode: statusCode))))

        await #expect(throws: ChatResponseLoader.Error.invalidData) {
            try await sut.load(from: "any message")
        }
    }

    @Test func load_deliversInvalidDataErrorOnNonHTTPResponse() async {
        let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let (sut, _) = makeSUT(result: .success((Data("a message".utf8), nonHTTPResponse)))

        await #expect(throws: ChatResponseLoader.Error.invalidData) {
            try await sut.load(from: "any message")
        }
    }

    @Test func load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidData() async {
        let invalidUTF8 = Data([0xFF])
        let (sut, _) = makeSUT(result: .success((invalidUTF8, httpResponse(statusCode: 200))))

        await #expect(throws: ChatResponseLoader.Error.invalidData) {
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
