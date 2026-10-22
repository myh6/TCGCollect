//
//  ImageDataLoaderCacheDecoratorTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import AppCore
import TestHelpers

struct ImageDataLoaderCacheDecoratorTests {

    @Test func init_doesNotLoadOrSave() {
        let (_, loader, cache) = makeSUT()

        #expect(loader.loadedURLs.isEmpty)
        #expect(cache.savedEntries.isEmpty)
    }

    @Test func loadImageData_loadsFromDecorateeForURL() async {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let (sut, loader, _) = makeSUT()

        _ = try? await sut.loadImageData(from: url)

        #expect(loader.loadedURLs == [url])
    }

    @Test func loadImageData_deliversDecorateeDataOnDecorateeSuccess() async throws {
        let imageData = Data("image data".utf8)
        let (sut, _, _) = makeSUT(loaderResult: .success(imageData))

        let data = try await sut.loadImageData(from: anyURL())

        #expect(data == imageData)
    }

    @Test func loadImageData_deliversDecorateeErrorOnDecorateeFailure() async {
        let loaderError = anyNSError()
        let (sut, _, _) = makeSUT(loaderResult: .failure(loaderError))

        await #expect(throws: loaderError) {
            try await sut.loadImageData(from: anyURL())
        }
    }

    @Test func loadImageData_savesLoadedDataForURLOnDecorateeSuccess() async throws {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let imageData = Data("image data".utf8)
        let (sut, _, cache) = makeSUT(loaderResult: .success(imageData))

        _ = try await sut.loadImageData(from: url)

        #expect(cache.savedEntries == [.init(data: imageData, url: url)])
    }

    @Test func loadImageData_doesNotSaveOnDecorateeFailure() async {
        let (sut, _, cache) = makeSUT(loaderResult: .failure(anyNSError()))

        _ = try? await sut.loadImageData(from: anyURL())

        #expect(cache.savedEntries.isEmpty)
    }

    // The cache only speeds things up: a failed save must not hide an image that did load.
    @Test func loadImageData_deliversDataEvenWhenSavingFails() async throws {
        let imageData = Data("image data".utf8)
        let (sut, _, _) = makeSUT(loaderResult: .success(imageData), saveResult: .failure(anyNSError()))

        let data = try await sut.loadImageData(from: anyURL())

        #expect(data == imageData)
    }

    // MARK: - Helpers
    private func makeSUT(
        loaderResult: Result<Data, Error> = .failure(anyNSError()),
        saveResult: Result<Void, Error> = .success(())
    ) -> (sut: ImageDataLoader, loader: ImageDataLoaderStub, cache: ImageDataCacheSpy) {
        let loader = ImageDataLoaderStub(result: loaderResult)
        let cache = ImageDataCacheSpy(result: saveResult)
        let sut = ImageDataLoaderCacheDecorator(decoratee: loader, cache: cache)
        return (sut, loader, cache)
    }

    private final class ImageDataLoaderStub: ImageDataLoader {
        private(set) var loadedURLs = [URL]()
        private let result: Result<Data, Error>

        init(result: Result<Data, Error>) {
            self.result = result
        }

        func loadImageData(from url: URL) async throws -> Data {
            loadedURLs.append(url)
            return try result.get()
        }
    }

    private final class ImageDataCacheSpy: ImageDataCache {
        struct Entry: Equatable {
            let data: Data
            let url: URL
        }

        private(set) var savedEntries = [Entry]()
        private let result: Result<Void, Error>

        init(result: Result<Void, Error>) {
            self.result = result
        }

        func save(_ data: Data, for url: URL) async throws {
            savedEntries.append(Entry(data: data, url: url))
            try result.get()
        }
    }
}
