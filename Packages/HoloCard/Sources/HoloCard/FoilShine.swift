//
//  FoilShine.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI

struct FoilShine: View {
    let tilt: HoloTilt

    private static let bandWidth = 0.3
    private static let peakOpacity = 0.8
    private static let travel = 0.9

    var body: some View {
        LinearGradient(stops: Self.band, startPoint: start, endPoint: end)
            .blendMode(.overlay)
            .opacity(0.35 + 0.65 * tilt.intensity)
            .allowsHitTesting(false)
    }

    private var start: UnitPoint {
        UnitPoint(x: tilt.pointer.x - Self.travel, y: tilt.pointer.y - Self.travel)
    }

    private var end: UnitPoint {
        UnitPoint(x: tilt.pointer.x + Self.travel, y: tilt.pointer.y + Self.travel)
    }

    private static var band: [Gradient.Stop] {
        [
            .init(color: .white.opacity(0), location: 0.5 - bandWidth / 2),
            .init(color: .white.opacity(peakOpacity), location: 0.5),
            .init(color: .white.opacity(0), location: 0.5 + bandWidth / 2),
        ]
    }
}
