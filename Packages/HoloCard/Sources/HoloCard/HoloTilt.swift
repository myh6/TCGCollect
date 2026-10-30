//
//  HoloTilt.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI

public struct HoloTilt: Equatable, Sendable {
    public static let resting = HoloTilt(pointer: .center)

    public let pointer: UnitPoint
    public let rotationX: Angle
    public let rotationY: Angle
    public let intensity: Double

    public init(pointer: UnitPoint, maxAngle: Angle = .degrees(15)) {
        let pointer = UnitPoint(x: pointer.x.clamped(to: 0...1), y: pointer.y.clamped(to: 0...1))
        let offsetFromCenter = CGVector(dx: (pointer.x - 0.5) * 2, dy: (0.5 - pointer.y) * 2)

        self.pointer = pointer
        self.rotationX = maxAngle * offsetFromCenter.dy
        self.rotationY = maxAngle * offsetFromCenter.dx
        self.intensity = hypot(offsetFromCenter.dx, offsetFromCenter.dy) / hypot(1, 1)
    }

    public init(location: CGPoint, in size: CGSize, maxAngle: Angle = .degrees(15)) {
        guard size.width > 0, size.height > 0 else {
            self.init(pointer: .center, maxAngle: maxAngle)
            return
        }
        self.init(pointer: UnitPoint(x: location.x / size.width, y: location.y / size.height), maxAngle: maxAngle)
    }

    public init(roll: Angle, pitch: Angle, range: Angle = .degrees(20), maxAngle: Angle = .degrees(15)) {
        guard range.degrees > 0 else {
            self.init(pointer: .center, maxAngle: maxAngle)
            return
        }
        let pointer = UnitPoint(
            x: 0.5 + roll.degrees / range.degrees / 2,
            y: 0.5 - pitch.degrees / range.degrees / 2
        )
        self.init(pointer: pointer, maxAngle: maxAngle)
    }
}

private extension Angle {
    static func * (angle: Angle, factor: Double) -> Angle {
        .degrees(angle.degrees * factor)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
