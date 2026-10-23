//
//  ImageComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Foundation
import Domain

/// Builds an image loader for card images. Images live on third-party hosts, so it uses a plain
/// client: wrapping it in `APIKeyHTTPClient` would send our backend's key to them.
public enum ImageComposer {
    public static func makeRemoteImageDataLoader(session: URLSession? = nil) -> ImageDataLoader {
        RemoteImageDataLoader(client: URLSessionHTTPClient(session: session ?? URLSession(configuration: .default)))
    }
}
