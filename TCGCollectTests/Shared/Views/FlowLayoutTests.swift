//
//  FlowLayoutTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import CoreGraphics
import Testing
@testable import TCGCollect

struct FlowLayoutTests {

    @Test func arrangement_isEmptyWithoutItems() {
        let sut = FlowLayout.arrangement(of: [], within: 100, spacing: 5)

        #expect(sut == .init(positions: [], size: .zero))
    }

    @Test func arrangement_placesItemsInOneRowWhenTheyFit() {
        let sut = FlowLayout.arrangement(of: [size(30, 10), size(40, 10)], within: 100, spacing: 5)

        #expect(sut == .init(positions: [point(0, 0), point(35, 0)], size: size(75, 10)))
    }

    @Test func arrangement_wrapsToNewRowBelowTallestItemWhenNextItemDoesNotFit() {
        let sut = FlowLayout.arrangement(of: [size(60, 10), size(50, 12), size(20, 10)], within: 100, spacing: 5)

        #expect(sut == .init(positions: [point(0, 0), point(0, 15), point(55, 15)], size: size(75, 27)))
    }

    @Test func arrangement_keepsItemWiderThanWidthOnItsOwnRow() {
        let sut = FlowLayout.arrangement(of: [size(150, 10), size(20, 10)], within: 100, spacing: 5)

        #expect(sut == .init(positions: [point(0, 0), point(0, 15)], size: size(150, 25)))
    }

    // MARK: - Helpers
    private func size(_ width: CGFloat, _ height: CGFloat) -> CGSize {
        CGSize(width: width, height: height)
    }

    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}
