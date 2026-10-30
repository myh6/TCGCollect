//
//  HoloTiltTests.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI
import Testing
import HoloCard

struct HoloTiltTests {

    @Test func resting_pointsAtCenterWithoutRotationOrIntensity() {
        let sut = HoloTilt.resting

        #expect(sut.pointer == .center)
        expectRotation(of: sut, x: 0, y: 0)
        #expect(sut.intensity == 0)
    }

    @Test(arguments: [
        (UnitPoint.leading, -1.0, 0.0),
        (.trailing, 1.0, 0.0),
        (.top, 0.0, 1.0),
        (.bottom, 0.0, -1.0),
        (.topTrailing, 1.0, 1.0),
    ])
    func rotation_tiltsTowardPointerUpToMaxAngle(pointer: UnitPoint, yFraction: Double, xFraction: Double) {
        let sut = HoloTilt(pointer: pointer, maxAngle: .degrees(20))

        expectRotation(of: sut, x: 20 * xFraction, y: 20 * yFraction)
    }

    @Test func rotation_isProportionalToDistanceFromCenter() {
        let sut = HoloTilt(pointer: UnitPoint(x: 0.75, y: 0.5), maxAngle: .degrees(20))

        expectRotation(of: sut, x: 0, y: 10)
    }

    @Test(arguments: [
        (UnitPoint.center, 0.0),
        (.trailing, sqrt(0.5)),
        (.top, sqrt(0.5)),
        (.topLeading, 1.0),
        (.bottomTrailing, 1.0),
    ])
    func intensity_growsFromZeroAtCenterToOneAtCorners(pointer: UnitPoint, intensity: Double) {
        let sut = HoloTilt(pointer: pointer)

        #expect(abs(sut.intensity - intensity) < 0.0001)
    }

    @Test func init_keepsPointerOnCard() {
        let sut = HoloTilt(pointer: UnitPoint(x: -0.5, y: 1.5))

        #expect(sut.pointer == .bottomLeading)
    }

    @Test(arguments: [
        (CGPoint(x: 0, y: 0), UnitPoint.topLeading),
        (CGPoint(x: 100, y: 75), .center),
        (CGPoint(x: 200, y: 150), .bottomTrailing),
        (CGPoint(x: 300, y: -20), .topTrailing),
    ])
    func initWithLocation_pointsAtLocationRelativeToCardSize(location: CGPoint, pointer: UnitPoint) {
        let sut = HoloTilt(location: location, in: CGSize(width: 200, height: 150))

        #expect(sut.pointer == pointer)
    }

    @Test func initWithLocation_restsOnEmptyCard() {
        let sut = HoloTilt(location: CGPoint(x: 10, y: 10), in: .zero)

        #expect(sut == .resting)
    }

    @Test func initWithMotion_restsWhilePhoneIsHeldAsAtStart() {
        let sut = HoloTilt(roll: .zero, pitch: .zero)

        #expect(sut == .resting)
    }

    @Test(arguments: [
        (20.0, 0.0, UnitPoint.trailing),
        (-20.0, 0.0, .leading),
        (0.0, 20.0, .top),
        (0.0, -20.0, .bottom),
        (20.0, 20.0, .topTrailing),
    ])
    func initWithMotion_movesPointerTowardWhereThePhoneTurnsUpToRange(roll: Double, pitch: Double, pointer: UnitPoint) {
        let sut = HoloTilt(roll: .degrees(roll), pitch: .degrees(pitch), range: .degrees(20))

        #expect(sut.pointer == pointer)
    }

    @Test func initWithMotion_movesPointerInProportionToTurn() {
        let sut = HoloTilt(roll: .degrees(10), pitch: .degrees(-5), range: .degrees(20))

        #expect(sut.pointer == UnitPoint(x: 0.75, y: 0.625))
    }

    @Test func initWithMotion_keepsPointerOnCardBeyondRange() {
        let sut = HoloTilt(roll: .degrees(90), pitch: .degrees(-90), range: .degrees(20))

        #expect(sut.pointer == .bottomTrailing)
    }

    @Test func initWithMotion_restsWithoutRange() {
        let sut = HoloTilt(roll: .degrees(10), pitch: .degrees(10), range: .zero)

        #expect(sut == .resting)
    }

    @Test func initWithMotion_rotatesUpToMaxAngle() {
        let sut = HoloTilt(roll: .degrees(20), pitch: .zero, range: .degrees(20), maxAngle: .degrees(8))

        expectRotation(of: sut, x: 0, y: 8)
    }

    // MARK: - Helpers
    private func expectRotation(
        of tilt: HoloTilt, x: Double, y: Double,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(abs(tilt.rotationX.degrees - x) < 0.0001, "rotationX", sourceLocation: sourceLocation)
        #expect(abs(tilt.rotationY.degrees - y) < 0.0001, "rotationY", sourceLocation: sourceLocation)
    }
}
