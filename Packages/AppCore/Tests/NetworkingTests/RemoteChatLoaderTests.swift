import Testing
@testable import Networking
import TestHelpers
import Domain

import Foundation

struct RemoteChatLoaderTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requests.isEmpty)
    }

    @Test func load_sendsSendMessageRequestFromBaseURL() async throws {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(baseURL: baseURL)

        _ = try? await sut.load(question: "a question")

        let expected = try ChatEndpoint.sendMessage("a question").urlRequest(baseURL: baseURL)
        #expect(client.requests == [expected])
        // URLRequest's == ignores httpBody, so compare the bodies explicitly.
        #expect(client.requests.map(\.httpBody) == [expected.httpBody])
    }

    @Test func loadTwice_sendsEachQuestionInOrder() async throws {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(baseURL: baseURL)

        _ = try? await sut.load(question: "first question")
        _ = try? await sut.load(question: "second question")

        let expected = [
            try ChatEndpoint.sendMessage("first question").urlRequest(baseURL: baseURL),
            try ChatEndpoint.sendMessage("second question").urlRequest(baseURL: baseURL),
        ]
        #expect(client.requests == expected)
        #expect(client.requests.map(\.httpBody) == expected.map(\.httpBody))
    }

    @Test func load_deliversClientErrorOnClientError() async {
        let clientError = anyNSError()
        let (sut, _) = makeSUT(result: .failure(clientError))

        await #expect(throws: clientError) {
            try await sut.load(question: "any question")
        }
    }

    @Test func load_deliversMapperErrorOnInvalidResponse() async {
        let (sut, _) = makeSUT(result: .success((Data("an answer".utf8), httpResponse(statusCode: 500))))

        await #expect(throws: ChatResponseMapper.Error.invalidData) {
            try await sut.load(question: "any question")
        }
    }

    @Test func load_deliversAnswerWithSuggestionsOn200HTTPResponseWithValidJSON() async throws {
        let json = Data(#"""
        {
            "answer": "an answer",
            "cards": [{
                "card_id": 1,
                "name": "a card",
                "current_price": "9.99",
                "currency": "USD",
                "current_fetched_at": "2026-01-01T00:00:00+00:00"
            }]
        }
        """#.utf8)
        let (sut, _) = makeSUT(result: .success((json, httpResponse(statusCode: 200))))

        let answer = try await sut.load(question: "any question")

        let expected = ChatAnswer(text: "an answer", suggestions: [
            ChatAnswer.Suggestion(
                card: Card(id: 1, name: "a card"),
                price: PricePoint(
                    cardID: 1,
                    date: Date(timeIntervalSince1970: 1_767_225_600),
                    price: Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")
                )
            )
        ])
        #expect(answer == expected)
    }

    // MARK: - Helpers
    private func makeSUT(
        baseURL: URL = anyURL(),
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError())
    ) -> (sut: ChatLoader, client: SpyClient) {
        let client = SpyClient(result: result)
        let sut = RemoteChatLoader(baseURL: baseURL, client: client)
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
