//
//  CallArrivals.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/26.
//

import Testing

/// Lets a test wait until a spy has received a given call, instead of polling for it.
/// The spy calls `record()` when each call arrives; the test calls `waitForCall(at:)`.
/// On the main actor, like the spies, so a call and the test waiting for it can't run at the same time.
@MainActor
final class CallArrivals {
    /// Shown in the issue when a call never arrives, e.g. "save" gives "save 0 never arrived".
    private let callName: String
    private(set) var count = 0
    // Tests waiting for a call, by the index of that call.
    private var waiters = [Int: CheckedContinuation<Void, Never>]()

    init(callName: String) {
        self.callName = callName
    }

    func record() {
        count += 1
        waiters.removeValue(forKey: count - 1)?.resume()
    }

    /// Returns once call number `index` has arrived, or records an issue if it hasn't within `timeout`.
    func waitForCall(
        at index: Int, timeout: Duration = .seconds(5),
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        guard count <= index else { return }
        let timeoutTask = Task { [weak self, callName] in
            try await Task.sleep(for: timeout)
            // Whichever comes first, the call or the timeout, removes the waiter, so it's resumed only once.
            guard let waiter = self?.waiters.removeValue(forKey: index) else { return }
            Issue.record("\(callName) \(index) never arrived", sourceLocation: sourceLocation)
            waiter.resume()
        }
        await withCheckedContinuation { waiters[index] = $0 }
        timeoutTask.cancel()
    }
}
