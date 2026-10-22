//
//  ImageDataLoaderCacheDecorator.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain
import Persistence

/// Saves what `decoratee` loads into `cache`, e.g. each download, so it can be loaded again without the network.
public struct ImageDataLoaderCacheDecorator: ImageDataLoader {
    private let decoratee: ImageDataLoader
    private let cache: ImageDataCache

    public init(decoratee: ImageDataLoader, cache: ImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func loadImageData(from url: URL) async throws -> Data {
        let data = try await decoratee.loadImageData(from: url)
        // The cache only speeds things up: a failed save mustn't hide an image that did load.
        try? await cache.save(data, for: url)
        return data
    }
}
