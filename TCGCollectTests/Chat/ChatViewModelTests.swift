//
//  ChatViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Testing
import AppCore
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

        await send(to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))

        #expect(loader.questions == ["a question"])
    }

    @Test func send_trimsWhitespaceAroundQuestion() async {
        let (sut, loader) = makeSUT()
        await send("  a question \n", to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))

        #expect(loader.questions == ["a question"])
    }

    @Test(arguments: ["", "   ", "\n"])
    func send_ignoresEmptyQuestion(question: String) async {
        let (sut, loader) = makeSUT()
        loader.setCompletionForNewCalls(to: .success(makeAnswer("an answer")))

        await sut.send(question)

        #expect(loader.questions.isEmpty)
        #expect(sut.state == .idle)
    }

    @Test func send_isLoadingWhileWaitingForAnswer() async {
        let (sut, loader) = makeSUT()

        let sending = await startSending(to: sut, loader: loader)
        #expect(sut.state == .loading)

        loader.complete(with: .success(makeAnswer("an answer")))
        await sending.value
    }

    @Test func send_deliversAnswerWithSuggestionsOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()
        let answer = makeAnswer("an answer", suggestions: [makeSuggestion(cardID: 1), makeSuggestion(cardID: 2)])

        await send(to: sut, loader: loader, completingWith: .success(answer))

        #expect(sut.state == .loaded(answer: answer))
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

        loader.complete(with: .success(makeAnswer("an answer")), at: 1)
        await sending.value
    }

    @Test func send_ignoresSendWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstSending = await startSending(to: sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success(makeAnswer("an answer")))

        await sut.send("another question")
        #expect(loader.questions == ["a question"])

        loader.complete(with: .success(makeAnswer("an answer")))
        await firstSending.value
    }

    @Test func cancel_withoutPendingRequestDoesNothing() {
        let (sut, loader) = makeSUT()

        sut.cancel()

        #expect(loader.cancelledCalls.isEmpty)
        #expect(sut.state == .idle)
    }

    @Test func cancel_cancelsPendingRequest() async {
        let (sut, loader) = makeSUT()
        let sending = await startSending(to: sut, loader: loader)

        sut.cancel()
        #expect(loader.cancelledCalls == [0])

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
        loader.complete(with: .success(makeAnswer("a late answer")))
        await sending.value

        #expect(sut.state == .idle)
    }

    @Test(arguments: [Result<ChatAnswer, Error>.failure(URLError(.cancelled)), .success(makeAnswer("a late answer"))])
    func cancel_restoresPreviousAnswer(lateResult: Result<ChatAnswer, Error>) async {
        let (sut, loader) = makeSUT()
        await send(to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))

        let sending = await startSending(to: sut, loader: loader, at: 1)
        sut.cancel()
        loader.complete(with: lateResult, at: 1)
        await sending.value

        #expect(sut.state == .loaded(answer: makeAnswer("an answer")))
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: ChatViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = ChatViewModel(loader: loader)
        return (sut, loader)
    }

    /// Starts sending `question` and returns once the loader has received request number `index`, which is still waiting.
    private func startSending(
        _ question: String = "a question", to sut: ChatViewModel, loader: LoaderSpy, at index: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let sending = Task { await sut.send(question) }
        await loader.waitForCall(at: index, sourceLocation: sourceLocation)
        return sending
    }

    private func send(
        _ question: String = "a question", to sut: ChatViewModel, loader: LoaderSpy, completingWith result: Result<ChatAnswer, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let sending = await startSending(question, to: sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await sending.value
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private final class LoaderSpy: HeldCalls<String, ChatAnswer>, ChatLoader {
        var questions: [String] { inputs }

        init() {
            super.init(callName: "request")
        }

        func load(question: String) async throws -> ChatAnswer {
            try await call(with: question)
        }
    }
}

// File-level, so `@Test(arguments:)` can use them too.
private func makeAnswer(_ text: String, suggestions: [ChatAnswer.Suggestion] = []) -> ChatAnswer {
    ChatAnswer(text: text, suggestions: suggestions)
}

private func makeSuggestion(cardID: Int) -> ChatAnswer.Suggestion {
    ChatAnswer.Suggestion(
        card: Card(id: cardID, name: "card \(cardID)"),
        price: PricePoint(cardID: cardID, date: Date(timeIntervalSince1970: 0), price: Money(amount: 1, currencyCode: "USD"))
    )
}
