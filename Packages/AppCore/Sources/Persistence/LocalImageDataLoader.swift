//
//  LocalImageDataLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

/// Loads and saves image data through an `ImageDataStore`.
public struct LocalImageDataLoader: ImageDataLoader, ImageDataCache {
    public enum LoadError: Error, Equatable {
        case failed
        case notFound
    }

    public enum SaveError: Error, Equatable {
        case failed
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

    public func save(_ data: Data, for url: URL) async throws {
        do {
            try await store.insert(data, for: url)
        } catch {
            throw SaveError.failed
        }
    }
}
