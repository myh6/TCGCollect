//
//  ImageLoader.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import AppCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Turns image data into images for views, keeping each decoded image in memory so it's decoded only once.
final class ImageLoader {
    enum Error: Swift.Error {
        case invalidImageData
    }

    private let dataLoader: ImageDataLoader
    private let memoryCache: ImageMemoryCache

    init(dataLoader: ImageDataLoader, memoryCache: ImageMemoryCache) {
        self.dataLoader = dataLoader
        self.memoryCache = memoryCache
    }

    /// The image already in memory, so a view can show it in its first frame instead of a placeholder.
    func cachedImage(for url: URL) -> PlatformImage? {
        memoryCache.image(for: url)
    }

    func loadImage(from url: URL) async throws -> PlatformImage {
        if let image = memoryCache.image(for: url) {
            return image
        }
        let data = try await dataLoader.loadImageData(from: url)
        guard let image = PlatformImage(data: data) else {
            throw Error.invalidImageData
        }
        memoryCache.insert(image, for: url)
        return image
    }
}
