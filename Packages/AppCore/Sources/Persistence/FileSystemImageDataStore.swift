//
//  FileSystemImageDataStore.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import CryptoKit

/// Keeps each image's data in its own file inside `directory`.
public struct FileSystemImageDataStore: ImageDataStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func retrieve(dataForURL url: URL) async throws -> Data? {
        let fileURL = fileURL(for: url)
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        return try Data(contentsOf: fileURL)
    }

    public func insert(_ data: Data, for url: URL) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Atomic, so a reader never sees a half-written file.
        try data.write(to: fileURL(for: url), options: .atomic)
    }

    /// URLs contain characters a file name can't, so the file is named by a hash of the URL.
    private func fileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = hash.map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name)
    }
}
