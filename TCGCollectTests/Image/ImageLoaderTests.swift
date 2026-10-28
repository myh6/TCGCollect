//
//  ImageLoaderTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import ImageIO
import UniformTypeIdentifiers
import AppCore
@testable import TCGCollect
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
struct ImageLoaderTests {

    @Test func init_doesNotLoadImageData() {
        let (_, dataLoader, _) = makeSUT()

        #expect(dataLoader.loadedURLs.isEmpty)
    }

    @Test func cachedImage_deliversImageInMemoryCache() {
        let url = anyURL()
        let image = PlatformImage()
        let (sut, _, memoryCache) = makeSUT()
        memoryCache.insert(image, for: url)

        #expect(sut.cachedImage(for: url) === image)
    }

    @Test func cachedImage_deliversNothingWithoutLoadingWhenNotInMemoryCache() {
        let (sut, dataLoader, _) = makeSUT()

        #expect(sut.cachedImage(for: anyURL()) == nil)
        #expect(dataLoader.loadedURLs.isEmpty)
    }

    @Test func loadImage_deliversImageInMemoryCacheWithoutLoadingData() async throws {
        let url = anyURL()
        let image = PlatformImage()
        let (sut, dataLoader, memoryCache) = makeSUT()
        memoryCache.insert(image, for: url)

        let loaded = try await sut.loadImage(from: url)

        #expect(loaded === image)
        #expect(dataLoader.loadedURLs.isEmpty)
    }

    @Test func loadImage_loadsDataForURLNotInMemoryCache() async {
        let url = anyURL()
        let (sut, dataLoader, _) = makeSUT()

        _ = try? await sut.loadImage(from: url)

        #expect(dataLoader.loadedURLs == [url])
    }

    @Test func loadImage_deliversImageDecodedFromLoadedData() async throws {
        let (sut, _, _) = makeSUT(dataResult: .success(makeImageData(width: 2, height: 3)))

        let image = try await sut.loadImage(from: anyURL())

        #expect(image.size == CGSize(width: 2, height: 3))
    }

    @Test func loadImage_keepsDecodedImageInMemoryCache() async throws {
        let url = anyURL()
        let (sut, _, memoryCache) = makeSUT(dataResult: .success(makeImageData(width: 2, height: 3)))

        let image = try await sut.loadImage(from: url)

        #expect(memoryCache.image(for: url) === image)
    }

    @Test func loadImage_deliversDataLoaderErrorOnDataLoaderFailure() async {
        let dataLoaderError = anyNSError()
        let (sut, _, _) = makeSUT(dataResult: .failure(dataLoaderError))

        await #expect(throws: dataLoaderError) {
            try await sut.loadImage(from: anyURL())
        }
    }

    @Test func loadImage_deliversInvalidImageDataErrorWithoutCachingOnDataThatIsNotAnImage() async {
        let url = anyURL()
        let (sut, _, memoryCache) = makeSUT(dataResult: .success(Data("not an image".utf8)))

        await #expect(throws: ImageLoader.Error.invalidImageData) {
            try await sut.loadImage(from: url)
        }
        #expect(memoryCache.image(for: url) == nil)
    }

    // MARK: - Helpers
    private func makeSUT(
        dataResult: Result<Data, Error> = .failure(anyNSError())
    ) -> (sut: ImageLoader, dataLoader: ImageDataLoaderStub, memoryCache: ImageMemoryCache) {
        let dataLoader = ImageDataLoaderStub(result: dataResult)
        let memoryCache = ImageMemoryCache()
        let sut = ImageLoader(dataLoader: dataLoader, memoryCache: memoryCache)
        return (sut, dataLoader, memoryCache)
    }

    private func anyURL() -> URL {
        URL(string: "https://an-image-url.com/card.png")!
    }

    /// A real PNG of the given size in pixels, so decoding can be checked without bundling a file.
    private func makeImageData(width: Int, height: Int) -> Data {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
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

private func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}
