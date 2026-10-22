//
//  ImageDataCache.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation

/// Keeps downloaded image data so it can be loaded again without the network.
public protocol ImageDataCache {
    func save(_ data: Data, for url: URL) async throws
}
