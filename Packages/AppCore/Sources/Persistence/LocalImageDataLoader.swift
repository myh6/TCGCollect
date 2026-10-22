//
//  LocalImageDataLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

/// Loads image data that was cached in an `ImageDataStore`.
public struct LocalImageDataLoader: ImageDataLoader {
    public enum LoadError: Error, Equatable {
        case failed
        case notFound
    }

    private let store: ImageDataStore

    public init(store: ImageDataStore) {
        self.store = store
    }

    public func loadImageData(from url: URL) async throws -> Data {
        let data: Data?
        do {
            data = try await store.retrieve(dataForURL: url)
        } catch {
            throw LoadError.failed
        }
        guard let data else { throw LoadError.notFound }
        return data
    }
}
