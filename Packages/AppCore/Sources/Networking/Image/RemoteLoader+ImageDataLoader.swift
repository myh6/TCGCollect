//
//  RemoteLoader+ImageDataLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Domain

extension RemoteLoader: ImageDataLoader where Input == URL, Resource == Data {
    public func loadImageData(from url: URL) async throws -> Data {
        try await load(url)
    }
}
