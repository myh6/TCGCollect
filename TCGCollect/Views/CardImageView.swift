//
//  CardImageView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import SwiftUI

/// A card's image, loaded through the environment's `ImageLoader`, with a placeholder while loading or when there's none.
struct CardImageView: View {
    let url: URL?

    @Environment(\.imageLoader) private var imageLoader
    // Remembers which URL the image or failure is for, so a reused view never shows another card's image.
    @State private var result: (url: URL, image: PlatformImage?)?

    var body: some View {
        content
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let image = currentImage {
            Image(platformImage: image).resizable().scaledToFit()
        } else if url != nil, imageLoader != nil, result?.url != url {
            placeholder { ProgressView() }
        } else {
            // No URL, no loader (e.g. in previews), or the image failed to load.
            placeholder { Image(systemName: "photo").foregroundStyle(.secondary) }
        }
    }

    /// The loaded image, or one already in memory, so a tile scrolled back into view shows it in its first frame.
    private var currentImage: PlatformImage? {
        guard let url else { return nil }
        if let result, result.url == url { return result.image }
        return imageLoader?.cachedImage(for: url)
    }

    private func load() async {
        guard let url, let imageLoader, currentImage == nil else { return }
        do {
            let image = try await imageLoader.loadImage(from: url)
            result = (url, image)
        } catch {
            // Cancelled because the view went away or its URL changed: nothing to show.
            guard !Task.isCancelled else { return }
            result = (url, nil)
        }
    }

    private func placeholder(@ViewBuilder content: () -> some View) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.quaternary)
            .overlay(content())
    }
}

extension EnvironmentValues {
    /// nil unless the app provides one, so previews show placeholders instead of loading.
    @Entry var imageLoader: ImageLoader?
}

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
