//
//  HeldCalls.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Testing
import os

/// Holds every call until the test completes it, so tests can look at the in-between state.
@MainActor
class HeldCalls<Input, Output> {
    private(set) var inputs = [Input]()
    // nil once completed, so no call is resumed twice.
    private var completions = [CheckedContinuation<Output, Error>?]()
    private var resultForNewCalls: Result<Output, Error>?
    private let callName: String
    private let arrivals: CallArrivals
    // Cancellation handlers can run on any thread, so they write through a lock.
    private let cancelled = OSAllocatedUnfairLock(initialState: [Int]())

    init(callName: String) {
        self.callName = callName
        self.arrivals = CallArrivals(callName: callName)
    }

    /// Indices of the calls whose task was cancelled while waiting.
    var cancelledCalls: [Int] { cancelled.withLock { $0 } }

    func call(with input: Input) async throws -> Output {
        inputs.append(input)
        arrivals.record()
        if let resultForNewCalls {
            completions.append(nil)
            return try resultForNewCalls.get()
        }
        let index = inputs.count - 1
        let cancelled = cancelled
        // Like URLSession, notice cancellation, but leave it to the test to say how the call ends.
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { completions.append($0) }
        } onCancel: {
            cancelled.withLock { $0.append(index) }
        }
    }

    func waitForCall(at index: Int, sourceLocation: SourceLocation = #_sourceLocation) async {
        await arrivals.waitForCall(at: index, sourceLocation: sourceLocation)
    }

    /// Calls that arrive from now on complete right away, so a call that should be ignored
    /// but arrives anyway shows up in `inputs` instead of leaving the test waiting.
    /// Calls already waiting stay held until `complete(with:at:)`.
    func setCompletionForNewCalls(to result: Result<Output, Error>) {
        resultForNewCalls = result
    }

    func complete(with result: Result<Output, Error>, at index: Int = 0) {
        guard completions.indices.contains(index), let completion = completions[index] else {
            Issue.record("No waiting \(callName) at index \(index) to complete")
            return
        }
        completions[index] = nil
        completion.resume(with: result)
    }
}
