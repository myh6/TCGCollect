//
//  DeviceMotion.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/30.
//

#if os(iOS)
import CoreMotion
import SwiftUI

enum DeviceMotion {
    static var isAvailable: Bool {
        CMMotionManager().isDeviceMotionAvailable
    }

    static func tilts(range: Angle, maxAngle: Angle) -> AsyncStream<HoloTilt> {
        AsyncStream { continuation in
            let motion = MotionUpdates()
            motion.start { turn in
                continuation.yield(HoloTilt(roll: turn.roll, pitch: turn.pitch, range: range, maxAngle: maxAngle))
            }
            continuation.onTermination = { _ in motion.stop() }
        }
    }
}

private final class MotionUpdates: @unchecked Sendable {
    private let manager = CMMotionManager()
    private var turnSinceStart = TurnSinceStart()

    func start(onTurn: @escaping (TurnSinceStart.Turn) -> Void) {
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }
            onTurn(turnSinceStart.turn(forReadingRoll: .radians(attitude.roll), pitch: .radians(attitude.pitch)))
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
#endif
