//
//  RainbowShine.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI

struct RainbowShine: View {
    let tilt: HoloTilt

    private static let bandColors: [Color] = [
        Color(hue: 0.00, saturation: 0.45, brightness: 1),
        Color(hue: 0.13, saturation: 0.45, brightness: 1),
        Color(hue: 0.33, saturation: 0.4, brightness: 1),
        Color(hue: 0.50, saturation: 0.45, brightness: 1),
        Color(hue: 0.66, saturation: 0.4, brightness: 1),
        Color(hue: 0.83, saturation: 0.4, brightness: 1),
    ]
    private static let repeats = 7
    private static let travel = 1.5

    var body: some View {
        LinearGradient(colors: Self.repeatedBands, startPoint: start, endPoint: end)
            .blendMode(.hardLight)
            .opacity(0.2 + 0.5 * tilt.intensity)
            .allowsHitTesting(false)
    }

    private var start: UnitPoint {
        UnitPoint(x: tilt.pointer.x - Self.travel, y: tilt.pointer.y - Self.travel)
    }

    private var end: UnitPoint {
        UnitPoint(x: tilt.pointer.x + Self.travel, y: tilt.pointer.y + Self.travel)
    }

    private static var repeatedBands: [Color] {
        Array(repeating: bandColors + [bandColors[0]], count: repeats).flatMap { $0 }
    }
}
