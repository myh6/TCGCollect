//
//  ImageMemoryCache.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Decoded images kept in memory, so scrolling back to a card shows it at once without reading or decoding again.
/// NSCache drops images by itself when the system needs memory, so this is only ever a speed-up.
final class ImageMemoryCache {
    private let cache = NSCache<NSURL, PlatformImage>()

    init(countLimit: Int = 200) {
        cache.countLimit = countLimit
    }

    func image(for url: URL) -> PlatformImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: PlatformImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
