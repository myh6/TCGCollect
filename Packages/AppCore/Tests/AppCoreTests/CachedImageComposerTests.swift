//
//  CachedImageComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import AppCore
import TestHelpers

/// Runs the whole chain against real files. Swift Testing makes a new instance per test,
/// so each test gets its own cache folder, and `deinit` removes it.
final class CachedImageComposerTests {
    private let cacheDirectory = FileManager.default.temporaryDirectory
        .appending(path: "CachedImageComposerTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    @Test func loadImageData_downloadsImageNotInCache() async throws {
        let url = anyImageURL()
        let imageData = Data("image data".utf8)
        let remote = RemoteLoaderStub(result: .success(imageData))
        let sut = makeSUT(remote: remote)

        let data = try await sut.loadImageData(from: url)

        #expect(data == imageData)
        #expect(remote.loadedURLs == [url])
    }

    @Test func loadImageData_deliversCachedImageWithoutDownloadingAgain() async throws {
        let url = anyImageURL()
        let imageData = Data("image data".utf8)
        let remote = RemoteLoaderStub(result: .success(imageData))
        let sut = makeSUT(remote: remote)

        _ = try await sut.loadImageData(from: url)
        let data = try await sut.loadImageData(from: url)

        #expect(data == imageData)
        #expect(remote.loadedURLs == [url])
    }

    // Like the app starting again: a new loader on the same folder finds what was downloaded before.
    @Test func loadImageData_deliversImageCachedByAnotherInstanceWithoutDownloading() async throws {
        let url = anyImageURL()
        let imageData = Data("image data".utf8)
        _ = try await makeSUT(remote: RemoteLoaderStub(result: .success(imageData))).loadImageData(from: url)
        let offlineRemote = RemoteLoaderStub(result: .failure(anyNSError()))

        let data = try await makeSUT(remote: offlineRemote).loadImageData(from: url)

        #expect(data == imageData)
        #expect(offlineRemote.loadedURLs.isEmpty)
    }

    @Test func loadImageData_deliversRemoteErrorForImageNotInCacheWhenDownloadFails() async {
        let remoteError = anyNSError()
        let sut = makeSUT(remote: RemoteLoaderStub(result: .failure(remoteError)))

        await #expect(throws: remoteError) {
            try await sut.loadImageData(from: self.anyImageURL())
        }
    }

    // MARK: - Helpers
    private func makeSUT(remote: ImageDataLoader) -> ImageDataLoader {
        CachedImageComposer.makeImageDataLoader(remote: remote, cacheDirectory: cacheDirectory)
    }

    private func anyImageURL() -> URL {
        URL(string: "https://an-image-url.com/card.png")!
    }

    private final class RemoteLoaderStub: ImageDataLoader {
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
