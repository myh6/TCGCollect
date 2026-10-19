import Testing
@testable import Networking
import TestHelpers

import Foundation

final class ChatResponseLoaderTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requests.isEmpty)
    }

    @Test func load_sendsSendMessageRequestFromBaseURL() async throws {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(baseURL: baseURL)

        _ = try? await sut.load(from: "a message")

        let expected = try ChatEndpoint.sendMessage("a message").urlRequest(baseURL: baseURL)
        #expect(client.requests == [expected])
        // URLRequest's == ignores httpBody, so compare the bodies explicitly.
        #expect(client.requests.map(\.httpBody) == [expected.httpBody])
    }

    @Test func loadTwice_sendsEachMessageInOrder() async throws {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(baseURL: baseURL)

        _ = try? await sut.load(from: "first message")
        _ = try? await sut.load(from: "second message")

        let expected = [
            try ChatEndpoint.sendMessage("first message").urlRequest(baseURL: baseURL),
            try ChatEndpoint.sendMessage("second message").urlRequest(baseURL: baseURL),
        ]
        #expect(client.requests == expected)
        #expect(client.requests.map(\.httpBody) == expected.map(\.httpBody))
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

    @Test func load_deliversAnswerOn200HTTPResponseWithValidJSON() async throws {
        let json = Data(#"{"answer": "an answer", "cards": []}"#.utf8)
        let (sut, _) = makeSUT(result: .success((json, httpResponse(statusCode: 200))))

        let answer = try await sut.load(from: "any message")

        #expect(answer == "an answer")
    }

    // MARK: - Helpers
    private func makeSUT(
        baseURL: URL = anyURL(),
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError())
    ) -> (sut: ChatResponseLoader, client: SpyClient) {
        let client = SpyClient(result: result)
        let sut = ChatResponseLoader(baseURL: baseURL, client: client)
        return (sut, client)
    }

    final class SpyClient: NetworkClient {
        private(set) var requests = [URLRequest]()
        private let result: Result<URLResult, Error>

        init(result: Result<URLResult, Error>) {
            self.result = result
        }

        func perform(_ request: URLRequest) async throws -> URLResult {
            requests.append(request)
            return try result.get()
        }
    }
}
