//
//  FileSystemImageDataStoreTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import Persistence

/// Uses real files. Swift Testing makes a new instance per test, so each test gets its own
/// folder, and `deinit` removes it.
final class FileSystemImageDataStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "FileSystemImageDataStoreTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func retrieve_deliversNilWhenNothingIsStored() async throws {
        let sut = makeSUT()

        let data = try await sut.retrieve(dataForURL: anyImageURL())

        #expect(data == nil)
    }

    @Test func retrieve_deliversDataInsertedForURL() async throws {
        let url = anyImageURL()
        let imageData = Data("image data".utf8)
        let sut = makeSUT()

        try await sut.insert(imageData, for: url)
        let data = try await sut.retrieve(dataForURL: url)

        #expect(data == imageData)
    }

    @Test func insert_replacesDataPreviouslyInsertedForURL() async throws {
        let url = anyImageURL()
        let sut = makeSUT()

        try await sut.insert(Data("first".utf8), for: url)
        try await sut.insert(Data("second".utf8), for: url)
        let data = try await sut.retrieve(dataForURL: url)

        #expect(data == Data("second".utf8))
    }

    @Test func insert_keepsDataOfOtherURLs() async throws {
        let url1 = URL(string: "https://an-image-url.com/1.png")!
        let url2 = URL(string: "https://an-image-url.com/2.png?size=large")!
        let sut = makeSUT()

        try await sut.insert(Data("first".utf8), for: url1)
        try await sut.insert(Data("second".utf8), for: url2)

        #expect(try await sut.retrieve(dataForURL: url1) == Data("first".utf8))
        #expect(try await sut.retrieve(dataForURL: url2) == Data("second".utf8))
    }

    // Like the app starting again: a new store on the same folder finds what was saved before.
    @Test func retrieve_deliversDataInsertedByAnotherInstanceOnTheSameDirectory() async throws {
        let url = anyImageURL()
        let imageData = Data("image data".utf8)

        try await makeSUT().insert(imageData, for: url)
        let data = try await makeSUT().retrieve(dataForURL: url)

        #expect(data == imageData)
    }

    @Test func insert_failsWhenDirectoryCannotBeCreated() async throws {
        // A regular file where the folder should be.
        try Data("not a folder".utf8).write(to: directory)
        let sut = makeSUT()

        await #expect(throws: (any Error).self) {
            try await sut.insert(Data("image data".utf8), for: self.anyImageURL())
        }
    }

    @Test func retrieve_failsWhenStoredFileCannotBeRead() async throws {
        let url = anyImageURL()
        let sut = makeSUT()
        try await sut.insert(Data("image data".utf8), for: url)
        try makeStoredFilesUnreadable()

        await #expect(throws: (any Error).self) {
            try await sut.retrieve(dataForURL: url)
        }
    }

    // MARK: - Helpers
    private func makeStoredFilesUnreadable() throws {
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path(percentEncoded: false))
        }
    }

    private func makeSUT() -> FileSystemImageDataStore {
        FileSystemImageDataStore(directory: directory)
    }

    private func anyImageURL() -> URL {
        URL(string: "https://an-image-url.com/card.png")!
    }
}
