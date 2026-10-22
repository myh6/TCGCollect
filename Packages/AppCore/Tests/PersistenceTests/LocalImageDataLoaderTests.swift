//
//  LocalImageDataLoaderTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
@testable import Persistence
import TestHelpers

struct LocalImageDataLoaderTests {

    @Test func init_doesNotMessageStore() {
        let (_, store) = makeSUT()

        #expect(store.messages.isEmpty)
    }

    @Test func loadImageData_requestsStoredDataForURL() async {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let (sut, store) = makeSUT()

        _ = try? await sut.loadImageData(from: url)

        #expect(store.messages == [.retrieve(url)])
    }

    @Test func loadImageData_failsOnStoreError() async {
        let (sut, store) = makeSUT()
        store.retrievalResult = .failure(anyNSError())

        await #expect(throws: LocalImageDataLoader.LoadError.failed) {
            try await sut.loadImageData(from: anyURL())
        }
    }

    @Test func loadImageData_deliversNotFoundErrorWhenNothingIsStored() async {
        let (sut, store) = makeSUT()
        store.retrievalResult = .success(nil)

        await #expect(throws: LocalImageDataLoader.LoadError.notFound) {
            try await sut.loadImageData(from: anyURL())
        }
    }

    @Test func loadImageData_deliversStoredData() async throws {
        let storedData = Data("image data".utf8)
        let (sut, store) = makeSUT()
        store.retrievalResult = .success(storedData)

        let data = try await sut.loadImageData(from: anyURL())

        #expect(data == storedData)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy()
        let sut = LocalImageDataLoader(store: store)
        return (sut, store)
    }

    private final class ImageDataStoreSpy: ImageDataStore {
        enum Message: Equatable {
            case retrieve(URL)
        }

        private(set) var messages = [Message]()
        var retrievalResult: Result<Data?, Error> = .success(nil)

        func retrieve(dataForURL url: URL) async throws -> Data? {
            messages.append(.retrieve(url))
            return try retrievalResult.get()
        }
    }
}
