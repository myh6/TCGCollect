//
//  FlowLayout.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI

struct FlowLayout: Layout {
    struct Arrangement: Equatable {
        let positions: [CGPoint]
        let size: CGSize
    }

    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(of: subviews, within: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let positions = arrangement(of: subviews, within: bounds.width).positions
        for (subview, position) in zip(subviews, positions) {
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangement(of subviews: Subviews, within width: CGFloat) -> Arrangement {
        Self.arrangement(of: subviews.map { $0.sizeThatFits(.unspecified) }, within: width, spacing: spacing)
    }

    static func arrangement(of sizes: [CGSize], within width: CGFloat, spacing: CGFloat) -> Arrangement {
        var positions = [CGPoint]()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for size in sizes {
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            widest = max(widest, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return Arrangement(positions: positions, size: CGSize(width: widest, height: y + rowHeight))
    }
}
