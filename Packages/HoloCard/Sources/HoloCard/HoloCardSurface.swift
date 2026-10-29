//
//  HoloCardSurface.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI

public struct HoloCardSurface<Card: View>: View {
    private let tilt: HoloTilt
    private let style: HoloStyle
    private let isLit: Bool
    private let cornerRadius: CGFloat
    private let card: Card

    public init(tilt: HoloTilt, style: HoloStyle = .plain, isLit: Bool, cornerRadius: CGFloat = 12, @ViewBuilder card: () -> Card) {
        self.tilt = tilt
        self.style = style
        self.isLit = isLit
        self.cornerRadius = cornerRadius
        self.card = card()
    }

    public var body: some View {
        card
            .overlay { shine }
            .overlay { glare }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .rotation3DEffect(tilt.rotationX, axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .rotation3DEffect(tilt.rotationY, axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .shadow(color: .black.opacity(0.35), radius: 12, x: -tilt.rotationY.degrees, y: 8 + tilt.rotationX.degrees)
    }

    @ViewBuilder
    private var shine: some View {
        switch style {
        case .plain:
            EmptyView()
        case .foil:
            FoilShine(tilt: tilt)
        case .rainbow:
            RainbowShine(tilt: tilt)
        }
    }

    private var glare: some View {
        GeometryReader { proxy in
            RadialGradient(
                colors: [.white.opacity(0.7), .white.opacity(0.15), .clear],
                center: tilt.pointer,
                startRadius: 0,
                endRadius: max(proxy.size.width, proxy.size.height) * 0.6
            )
        }
        .blendMode(.screen)
        .opacity(isLit ? 0.5 + 0.5 * tilt.intensity : 0)
        .allowsHitTesting(false)
    }
}
