//
//  ImageMemoryCacheTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
@testable import TCGCollect
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ImageMemoryCacheTests {

    @Test func image_deliversNothingForURLNotInserted() {
        let sut = ImageMemoryCache()

        #expect(sut.image(for: anyURL()) == nil)
    }

    @Test func image_deliversInsertedImageForURL() {
        let sut = ImageMemoryCache()
        let image = anyImage()
        let url = anyURL()

        sut.insert(image, for: url)

        #expect(sut.image(for: url) === image)
    }

    @Test func image_deliversNothingForAnotherURL() {
        let sut = ImageMemoryCache()

        sut.insert(anyImage(), for: URL(string: "https://an-image-url.com/card.png")!)

        #expect(sut.image(for: URL(string: "https://another-image-url.com/card.png")!) == nil)
    }

    @Test func insert_replacesImageForSameURL() {
        let sut = ImageMemoryCache()
        let url = anyURL()
        let newImage = anyImage()

        sut.insert(anyImage(), for: url)
        sut.insert(newImage, for: url)

        #expect(sut.image(for: url) === newImage)
    }

    // MARK: - Helpers
    private func anyImage() -> PlatformImage {
        PlatformImage()
    }

    private func anyURL() -> URL {
        URL(string: "https://an-image-url.com/card.png")!
    }
}
