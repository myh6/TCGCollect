//
//  ImageDataLoaderWithFallback.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

/// Loads from `primary`, and from `fallback` when that fails, e.g. the disk cache first, then the network.
public struct ImageDataLoaderWithFallback: ImageDataLoader {
    private let primary: ImageDataLoader
    private let fallback: ImageDataLoader

    public init(primary: ImageDataLoader, fallback: ImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func loadImageData(from url: URL) async throws -> Data {
        do {
            return try await primary.loadImageData(from: url)
        } catch {
            return try await fallback.loadImageData(from: url)
        }
    }
}
