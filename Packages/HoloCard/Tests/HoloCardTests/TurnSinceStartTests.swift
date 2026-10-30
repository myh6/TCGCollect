//
//  TurnSinceStartTests.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI
import Testing
@testable import HoloCard

struct TurnSinceStartTests {

    @Test func firstReading_isNoTurn() {
        var sut = TurnSinceStart()

        let turn = sut.turn(forReadingRoll: .degrees(12), pitch: .degrees(40))

        expect(turn, roll: 0, pitch: 0)
    }

    @Test func laterReadings_areTurnedSinceFirstReading() {
        var sut = TurnSinceStart()
        _ = sut.turn(forReadingRoll: .degrees(12), pitch: .degrees(40))

        let first = sut.turn(forReadingRoll: .degrees(22), pitch: .degrees(35))
        let second = sut.turn(forReadingRoll: .degrees(2), pitch: .degrees(50))

        expect(first, roll: 10, pitch: -5)
        expect(second, roll: -10, pitch: 10)
    }

    // MARK: - Helpers
    private func expect(
        _ turn: TurnSinceStart.Turn, roll: Double, pitch: Double,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(abs(turn.roll.degrees - roll) < 0.0001, "roll", sourceLocation: sourceLocation)
        #expect(abs(turn.pitch.degrees - pitch) < 0.0001, "pitch", sourceLocation: sourceLocation)
    }
}
