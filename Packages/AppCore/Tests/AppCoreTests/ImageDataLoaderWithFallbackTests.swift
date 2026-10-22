//
//  ImageDataLoaderWithFallbackTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import AppCore
import TestHelpers

struct ImageDataLoaderWithFallbackTests {

    @Test func init_doesNotLoad() {
        let (_, primary, fallback) = makeSUT()

        #expect(primary.loadedURLs.isEmpty)
        #expect(fallback.loadedURLs.isEmpty)
    }

    @Test func loadImageData_loadsFromPrimaryFirst() async {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let (sut, primary, _) = makeSUT(primaryResult: .success(anyData()))

        _ = try? await sut.loadImageData(from: url)

        #expect(primary.loadedURLs == [url])
    }

    @Test func loadImageData_deliversPrimaryDataWithoutLoadingFromFallbackOnPrimarySuccess() async throws {
        let primaryData = Data("primary data".utf8)
        let (sut, _, fallback) = makeSUT(primaryResult: .success(primaryData))

        let data = try await sut.loadImageData(from: anyURL())

        #expect(data == primaryData)
        #expect(fallback.loadedURLs.isEmpty)
    }

    @Test func loadImageData_loadsSameURLFromFallbackOnPrimaryFailure() async {
        let url = URL(string: "https://an-image-url.com/card.png")!
        let (sut, _, fallback) = makeSUT(primaryResult: .failure(anyNSError()))

        _ = try? await sut.loadImageData(from: url)

        #expect(fallback.loadedURLs == [url])
    }

    @Test func loadImageData_deliversFallbackDataOnPrimaryFailure() async throws {
        let fallbackData = Data("fallback data".utf8)
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackData))

        let data = try await sut.loadImageData(from: anyURL())

        #expect(data == fallbackData)
    }

    @Test func loadImageData_deliversFallbackErrorOnBothFailures() async {
        let fallbackError = NSError(domain: "fallback error", code: 1)
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .failure(fallbackError))

        await #expect(throws: fallbackError) {
            try await sut.loadImageData(from: anyURL())
        }
    }

    // MARK: - Helpers
    private func makeSUT(
        primaryResult: Result<Data, Error> = .failure(anyNSError()),
        fallbackResult: Result<Data, Error> = .failure(anyNSError())
    ) -> (sut: ImageDataLoader, primary: ImageDataLoaderStub, fallback: ImageDataLoaderStub) {
        let primary = ImageDataLoaderStub(result: primaryResult)
        let fallback = ImageDataLoaderStub(result: fallbackResult)
        let sut = ImageDataLoaderWithFallback(primary: primary, fallback: fallback)
        return (sut, primary, fallback)
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
}
