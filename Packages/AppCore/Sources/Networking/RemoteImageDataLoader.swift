//
//  RemoteImageDataLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Foundation
import Domain

/// Downloads image data from wherever its URL points, usually a third-party host.
public struct RemoteImageDataLoader: ImageDataLoader {
    private let client: NetworkClient

    public init(client: NetworkClient) {
        self.client = client
    }

    public func loadImageData(from url: URL) async throws -> Data {
        let (data, _) = try await client.perform(URLRequest(url: url))
        return data
    }
}
