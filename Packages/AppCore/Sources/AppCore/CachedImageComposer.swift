//
//  CachedImageComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain
import Persistence

/// Builds an image loader that checks the disk cache first and downloads only on a miss,
/// saving each download for next time.
public enum CachedImageComposer {
    public static func makeImageDataLoader(remote: ImageDataLoader, cacheDirectory: URL) -> ImageDataLoader {
        let local = LocalImageDataLoader(store: FileSystemImageDataStore(directory: cacheDirectory))
        return ImageDataLoaderWithFallback(
            primary: local,
            fallback: ImageDataLoaderCacheDecorator(decoratee: remote, cache: local)
        )
    }
}
