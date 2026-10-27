import Testing
@testable import Networking
import TestHelpers
import Domain

import Foundation

struct RemoteImageDataLoaderTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requests.isEmpty)
    }

    @Test func loadImageData_requestsDataFromURLWithGET() async {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let (sut, client) = makeSUT()

        _ = try? await sut.loadImageData(from: url)

        #expect(client.requests.map(\.url) == [url])
        #expect(client.requests.map(\.httpMethod) == ["GET"])
    }

    @Test func loadImageDataTwice_requestsEachURLInOrder() async {
        let url1 = URL(string: "https://an-image-url.com/1.png")!
        let url2 = URL(string: "https://an-image-url.com/2.png")!
        let (sut, client) = makeSUT()

        _ = try? await sut.loadImageData(from: url1)
        _ = try? await sut.loadImageData(from: url2)

        #expect(client.requests.map(\.url) == [url1, url2])
    }

    @Test func loadImageData_deliversClientErrorOnClientError() async {
        let clientError = anyNSError()
        let (sut, _) = makeSUT(result: .failure(clientError))

        await #expect(throws: clientError) {
            try await sut.loadImageData(from: anyURL())
        }
    }

    @Test func loadImageData_deliversMapperErrorOnInvalidResponse() async {
        let (sut, _) = makeSUT(result: .success((anyData(), httpResponse(statusCode: 500))))

        await #expect(throws: ImageDataMapper.Error.invalidData) {
            try await sut.loadImageData(from: anyURL())
        }
    }

    @Test func loadImageData_deliversDataOn200HTTPResponseWithNonEmptyData() async throws {
        let imageData = Data("image data".utf8)
        let (sut, _) = makeSUT(result: .success((imageData, httpResponse(statusCode: 200))))

        let data = try await sut.loadImageData(from: anyURL())

        #expect(data == imageData)
    }

    // MARK: - Helpers
    private func makeSUT(
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError())
    ) -> (sut: ImageDataLoader, client: SpyClient) {
        let client = SpyClient(result: result)
        let sut = RemoteImageDataLoader(client: client)
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
