//
//  TurnSinceStart.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI

struct TurnSinceStart {
    struct Turn {
        let roll: Angle
        let pitch: Angle
    }

    private var start: Turn?

    mutating func turn(forReadingRoll roll: Angle, pitch: Angle) -> Turn {
        let reading = Turn(roll: roll, pitch: pitch)
        guard let start else {
            start = reading
            return Turn(roll: .zero, pitch: .zero)
        }
        return Turn(roll: reading.roll - start.roll, pitch: reading.pitch - start.pitch)
    }
}
