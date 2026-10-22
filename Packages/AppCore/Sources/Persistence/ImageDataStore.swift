//
//  ImageDataStore.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation

/// Where cached image bytes are kept, keyed by the URL they came from.
public protocol ImageDataStore {
    /// nil when nothing is stored for `url`.
    func retrieve(dataForURL url: URL) async throws -> Data?
}
