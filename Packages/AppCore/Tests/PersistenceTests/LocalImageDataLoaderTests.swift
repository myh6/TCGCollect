//
//  LocalImageDataLoaderTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import Domain
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

    @Test func save_insertsDataForURL() async {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let data = Data("image data".utf8)
        let (sut, store) = makeSUT()

        try? await sut.save(data, for: url)

        #expect(store.messages == [.insert(data, url)])
    }

    @Test func save_failsOnStoreInsertionError() async {
        let (sut, store) = makeSUT()
        store.insertionResult = .failure(anyNSError())

        await #expect(throws: LocalImageDataLoader.SaveError.failed) {
            try await sut.save(anyData(), for: anyURL())
        }
    }

    @Test func save_succeedsOnStoreInsertionSuccess() async throws {
        let (sut, store) = makeSUT()
        store.insertionResult = .success(())

        try await sut.save(anyData(), for: anyURL())
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: ImageDataLoader & ImageDataCache, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy()
        let sut = LocalImageDataLoader(store: store)
        return (sut, store)
    }

    private final class ImageDataStoreSpy: ImageDataStore {
        enum Message: Equatable {
            case retrieve(URL)
            case insert(Data, URL)
        }

        private(set) var messages = [Message]()
        var retrievalResult: Result<Data?, Error> = .success(nil)
        var insertionResult: Result<Void, Error> = .success(())

        func retrieve(dataForURL url: URL) async throws -> Data? {
            messages.append(.retrieve(url))
            return try retrievalResult.get()
        }

        func insert(_ data: Data, for url: URL) async throws {
            messages.append(.insert(data, url))
            try insertionResult.get()
        }
    }
}
