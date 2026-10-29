//
//  HoloCardView.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI

public struct HoloCardView<Card: View>: View {
    private let maxAngle: Angle
    private let cornerRadius: CGFloat
    private let card: Card

    @State private var tilt = HoloTilt.resting
    @State private var isTouching = false
    @State private var size = CGSize.zero

    public init(maxAngle: Angle = .degrees(15), cornerRadius: CGFloat = 12, @ViewBuilder card: () -> Card) {
        self.maxAngle = maxAngle
        self.cornerRadius = cornerRadius
        self.card = card()
    }

    public var body: some View {
        HoloCardSurface(tilt: tilt, isLit: isTouching, cornerRadius: cornerRadius) { card }
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
            .gesture(tiltGesture)
    }

    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                withAnimation(.interactiveSpring(duration: 0.2)) {
                    tilt = HoloTilt(location: drag.location, in: size, maxAngle: maxAngle)
                    isTouching = true
                }
            }
            .onEnded { _ in
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    tilt = .resting
                    isTouching = false
                }
            }
    }
}

#if DEBUG
#Preview("Drag the card") {
    HoloCardView { PreviewCard() }
        .frame(width: 260)
        .padding(40)
}

#Preview("Fixed tilts") {
    let pointers: [(String, UnitPoint)] = [("Resting", .center), ("Right", .trailing), ("Top", .top), ("Top left", .topLeading)]
    Grid(horizontalSpacing: 40, verticalSpacing: 40) {
        GridRow {
            ForEach(pointers.prefix(2), id: \.0) { name, pointer in
                tiltedCard(name, pointer: pointer)
            }
        }
        GridRow {
            ForEach(pointers.suffix(2), id: \.0) { name, pointer in
                tiltedCard(name, pointer: pointer)
            }
        }
    }
    .padding(30)
}

@MainActor
private func tiltedCard(_ name: String, pointer: UnitPoint) -> some View {
    VStack(spacing: 12) {
        HoloCardSurface(tilt: HoloTilt(pointer: pointer), isLit: pointer != .center) { PreviewCard() }
            .frame(width: 140)
        Text(name).font(.caption)
    }
}
#endif
