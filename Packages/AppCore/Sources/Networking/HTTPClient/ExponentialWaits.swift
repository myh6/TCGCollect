//
//  ExponentialWaits.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

extension Array where Element == Duration {
    public static func exponential(from first: Duration, upTo total: Duration) -> [Duration] {
        guard first > .zero else { return [] }
        var waits = [Duration]()
        var next = first
        var remaining = total
        while remaining > .zero {
            let wait = Swift.min(next, remaining)
            waits.append(wait)
            remaining -= wait
            next *= 2
        }
        return waits
    }
}
