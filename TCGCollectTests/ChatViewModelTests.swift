//
//  ChatViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Testing
import AppCore
import os
@testable import TCGCollect

// The loader spy holds requests until a test completes them, so a bug could leave one waiting forever.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ChatViewModelTests {

    @Test func init_startsIdleWithoutRequestingAnswer() {
        let (sut, loader) = makeSUT()

        #expect(sut.state == .idle)
        #expect(loader.questions.isEmpty)
    }

    @Test func send_requestsAnswerForQuestion() async {
        let (sut, loader) = makeSUT()

        await send(to: sut, loader: loader, completingWith: .success("an answer"))

        #expect(loader.questions == ["a question"])
    }

    @Test func send_trimsWhitespaceAroundQuestion() async {
        let (sut, loader) = makeSUT()
        await send("  a question \n", to: sut, loader: loader, completingWith: .success("an answer"))

        #expect(loader.questions == ["a question"])
    }

    @Test(arguments: ["", "   ", "\n"])
    func send_ignoresEmptyQuestion(question: String) async {
        let (sut, loader) = makeSUT()
        // In its own task: if it wrongly reached the loader, awaiting it here would never return.
        let sending = Task { await sut.send(question) }
        await giveTimeToReachLoader(loader, requestCount: 1)
        #expect(loader.questions.isEmpty)
        #expect(sut.state == .idle)

        loader.completeAllPending(with: .success("an answer"))
        await sending.value
    }

    @Test func send_isLoadingWhileWaitingForAnswer() async {
        let (sut, loader) = makeSUT()

        let sending = await startSending(to: sut, loader: loader)
        #expect(sut.state == .loading)

        loader.complete(with: .success("an answer"))
        await sending.value
    }

    @Test func send_deliversAnswerOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()

        await send(to: sut, loader: loader, completingWith: .success("an answer"))

        #expect(sut.state == .loaded(answer: "an answer"))
    }

    @Test func send_deliversCouldNotLoadAnswerErrorOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await send(to: sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.state == .failed(.couldNotLoadAnswer))
    }

    @Test func send_replacesPreviousErrorWithLoadingWhenSendingAgain() async {
        let (sut, loader) = makeSUT()
        await send(to: sut, loader: loader, completingWith: .failure(anyError()))

        let sending = await startSending(to: sut, loader: loader, at: 1)
        #expect(sut.state == .loading)

        loader.complete(with: .success("an answer"), at: 1)
        await sending.value
    }

    @Test func send_ignoresSendWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstSending = await startSending(to: sut, loader: loader)

        // In its own task: if it wrongly reached the loader, awaiting it here would never return.
        let secondSending = Task { await sut.send("another question") }
        await giveTimeToReachLoader(loader, requestCount: 2)
        #expect(loader.questions == ["a question"])

        loader.completeAllPending(with: .success("an answer"))
        await firstSending.value
        await secondSending.value
    }

    @Test func cancel_withoutPendingRequestDoesNothing() {
        let (sut, loader) = makeSUT()

        sut.cancel()

        #expect(loader.cancelledRequests.isEmpty)
        #expect(sut.state == .idle)
    }

    @Test func cancel_cancelsPendingRequest() async {
        let (sut, loader) = makeSUT()
        let sending = await startSending(to: sut, loader: loader)

        sut.cancel()
        #expect(loader.cancelledRequests == [0])

        loader.complete(with: .failure(URLError(.cancelled)))
        await sending.value
    }

    // URLSession reports a cancelled request as URLError(.cancelled); the user asked for it, so it isn't an error to show.
    @Test func cancel_returnsToIdleWithoutShowingError() async {
        let (sut, loader) = makeSUT()
        let sending = await startSending(to: sut, loader: loader)

        sut.cancel()
        loader.complete(with: .failure(URLError(.cancelled)))
        await sending.value

        #expect(sut.state == .idle)
    }

    @Test func cancel_ignoresAnswerArrivingAfterCancel() async {
        let (sut, loader) = makeSUT()
        let sending = await startSending(to: sut, loader: loader)

        sut.cancel()
        loader.complete(with: .success("a late answer"))
        await sending.value

        #expect(sut.state == .idle)
    }

    @Test(arguments: [Result<String, Error>.failure(URLError(.cancelled)), .success("a late answer")])
    func cancel_restoresPreviousAnswer(lateResult: Result<String, Error>) async {
        let (sut, loader) = makeSUT()
        await send(to: sut, loader: loader, completingWith: .success("an answer"))

        let sending = await startSending(to: sut, loader: loader, at: 1)
        sut.cancel()
        loader.complete(with: lateResult, at: 1)
        await sending.value

        #expect(sut.state == .loaded(answer: "an answer"))
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: ChatViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = ChatViewModel(loader: loader)
        return (sut, loader)
    }

    /// Starts sending `question` and returns once the loader has received request number `index`, which is still waiting.
    private func startSending(_ question: String = "a question", to sut: ChatViewModel, loader: LoaderSpy, at index: Int = 0) async -> Task<Void, Never> {
        let sending = Task { await sut.send(question) }
        for _ in 0..<1_000 where loader.questions.count <= index {
            await Task.yield()
        }
        #expect(loader.questions.count == index + 1, "Expected the loader to receive request \(index)")
        return sending
    }

    /// For a send that should be ignored: waits a bounded time for the loader to get `requestCount` requests anyway,
    /// so a send that wrongly goes through has the chance to show up before the test checks.
    private func giveTimeToReachLoader(_ loader: LoaderSpy, requestCount: Int) async {
        for _ in 0..<1_000 where loader.questions.count < requestCount {
            await Task.yield()
        }
    }

    private func send(_ question: String = "a question", to sut: ChatViewModel, loader: LoaderSpy, completingWith result: Result<String, Error>) async {
        let sending = await startSending(question, to: sut, loader: loader)
        loader.complete(with: result)
        await sending.value
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    /// Holds every `load` call until the test completes it, so tests can look at the in-between state.
    private final class LoaderSpy: ResponseLoader {
        private(set) var questions = [String]()
        // nil once completed, so no request is resumed twice.
        private var completions = [CheckedContinuation<String, Error>?]()
        // Set by completeAllPending, so a request that arrives late doesn't wait forever.
        private var resultForLaterRequests: Result<String, Error>?
        // Cancellation handlers can run on any thread, so they write through a lock.
        private let cancelled = OSAllocatedUnfairLock(initialState: [Int]())

        /// Indices of the requests whose task was cancelled while waiting.
        var cancelledRequests: [Int] { cancelled.withLock { $0 } }

        func load(from input: String) async throws -> String {
            questions.append(input)
            if let resultForLaterRequests {
                completions.append(nil)
                return try resultForLaterRequests.get()
            }
            let index = questions.count - 1
            let cancelled = cancelled
            // Like URLSession, notice cancellation, but leave it to the test to say how the request ends.
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { completions.append($0) }
            } onCancel: {
                cancelled.withLock { $0.append(index) }
            }
        }

        func complete(with result: Result<String, Error>, at index: Int = 0) {
            guard completions.indices.contains(index), let completion = completions[index] else {
                Issue.record("No waiting request at index \(index) to complete")
                return
            }
            completions[index] = nil
            completion.resume(with: result)
        }

        /// Completes every waiting request, and any that arrive later, with `result`.
        func completeAllPending(with result: Result<String, Error>) {
            resultForLaterRequests = result
            for index in completions.indices where completions[index] != nil {
                complete(with: result, at: index)
            }
        }
    }
}
