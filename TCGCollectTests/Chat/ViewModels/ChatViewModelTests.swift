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

    @Test func init_startsWithoutTurnsOrRequests() {
        let (sut, loader) = makeSUT()

        #expect(sut.turns.isEmpty)
        #expect(!sut.isWaitingForAnswer)
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
        #expect(sut.turns.map(\.question) == ["a question"])
    }

    @Test(arguments: ["", "   ", "\n"])
    func send_ignoresEmptyQuestion(question: String) async {
        let (sut, loader) = makeSUT()
        loader.setCompletionForNewCalls(to: .success(makeAnswer("an answer")))

        await sut.send(question)

        #expect(loader.questions.isEmpty)
        #expect(sut.turns.isEmpty)
    }

    @Test func send_showsQuestionWaitingForAnswer() async {
        let (sut, loader) = makeSUT()

        let sending = await startSending(to: sut, loader: loader)
        #expect(replies(of: sut) == [.waiting])
        #expect(sut.isWaitingForAnswer)

        loader.complete(with: .success(makeAnswer("an answer")))
        await sending.value
    }

    @Test func send_deliversAnswerWithSuggestionsOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()
        let answer = makeAnswer("an answer", suggestions: [makeSuggestion(cardID: 1), makeSuggestion(cardID: 2)])

        await send(to: sut, loader: loader, completingWith: .success(answer))

        #expect(replies(of: sut) == [.answered(answer)])
        #expect(!sut.isWaitingForAnswer)
    }

    @Test func send_deliversCouldNotLoadAnswerErrorOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await send(to: sut, loader: loader, completingWith: .failure(anyError()))

        #expect(replies(of: sut) == [.failed(.couldNotLoadAnswer)])
    }

    @Test func send_keepsEarlierTurnsInOrder() async {
        let (sut, loader) = makeSUT()
        await send("a question", to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))
        await send("a failing question", to: sut, loader: loader, at: 1, completingWith: .failure(anyError()))

        await send("a follow-up", to: sut, loader: loader, at: 2, completingWith: .success(makeAnswer("another answer")))

        #expect(sut.turns.map(\.question) == ["a question", "a failing question", "a follow-up"])
        #expect(replies(of: sut) == [.answered(makeAnswer("an answer")), .failed(.couldNotLoadAnswer), .answered(makeAnswer("another answer"))])
    }

    @Test func send_ignoresSendWhileWaitingForAnswer() async {
        let (sut, loader) = makeSUT()
        let firstSending = await startSending(to: sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success(makeAnswer("an answer")))

        await sut.send("another question")
        #expect(loader.questions == ["a question"])
        #expect(sut.turns.map(\.question) == ["a question"])

        loader.complete(with: .success(makeAnswer("an answer")))
        await firstSending.value
    }

    @Test func cancel_withoutPendingRequestDoesNothing() {
        let (sut, loader) = makeSUT()

        sut.cancel()

        #expect(loader.cancelledCalls.isEmpty)
        #expect(sut.turns.isEmpty)
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
    @Test(arguments: [Result<ChatAnswer, Error>.failure(URLError(.cancelled)), .success(makeAnswer("a late answer"))])
    func cancel_marksQuestionCancelledWhateverArrivesAfter(lateResult: Result<ChatAnswer, Error>) async {
        let (sut, loader) = makeSUT()
        await send(to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))
        let sending = await startSending("another question", to: sut, loader: loader, at: 1)

        sut.cancel()
        loader.complete(with: lateResult, at: 1)
        await sending.value

        #expect(replies(of: sut) == [.answered(makeAnswer("an answer")), .cancelled])
        #expect(!sut.isWaitingForAnswer)
    }

    @Test func retry_asksUnansweredQuestionAgainAtEndOfConversation() async {
        let (sut, loader) = makeSUT()
        await send("a failing question", to: sut, loader: loader, completingWith: .failure(anyError()))
        await send("a question", to: sut, loader: loader, at: 1, completingWith: .success(makeAnswer("an answer")))
        let failedTurn = sut.turns[0]

        let retrying = Task { await sut.retry(failedTurn) }
        await loader.waitForCall(at: 2)
        loader.complete(with: .success(makeAnswer("a retried answer")), at: 2)
        await retrying.value

        #expect(loader.questions.last == "a failing question")
        #expect(sut.turns.map(\.question) == ["a question", "a failing question"])
        #expect(replies(of: sut) == [.answered(makeAnswer("an answer")), .answered(makeAnswer("a retried answer"))])
    }

    @Test func retry_ignoresAnsweredQuestion() async {
        let (sut, loader) = makeSUT()
        await send(to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))
        loader.setCompletionForNewCalls(to: .success(makeAnswer("another answer")))

        await sut.retry(sut.turns[0])

        #expect(loader.questions == ["a question"])
        #expect(replies(of: sut) == [.answered(makeAnswer("an answer"))])
    }

    @Test func retry_ignoresRetryWhileWaitingForAnswer() async {
        let (sut, loader) = makeSUT()
        await send("a failing question", to: sut, loader: loader, completingWith: .failure(anyError()))
        let sending = await startSending(to: sut, loader: loader, at: 1)
        loader.setCompletionForNewCalls(to: .success(makeAnswer("an answer")))

        await sut.retry(sut.turns[0])
        #expect(loader.questions == ["a failing question", "a question"])

        loader.complete(with: .success(makeAnswer("an answer")), at: 1)
        await sending.value
    }

    @Test func startNewChat_clearsTurnsAndStartsNewConversation() async {
        let (sut, loader) = makeSUT()
        await send(to: sut, loader: loader, completingWith: .success(makeAnswer("an answer")))

        sut.startNewChat()

        #expect(sut.turns.isEmpty)
        #expect(loader.newConversationCount == 1)
    }

    @Test func startNewChat_cancelsPendingRequest() async {
        let (sut, loader) = makeSUT()
        let sending = await startSending(to: sut, loader: loader)

        sut.startNewChat()
        #expect(loader.cancelledCalls == [0])
        #expect(!sut.isWaitingForAnswer)

        loader.complete(with: .failure(URLError(.cancelled)))
        await sending.value
    }

    @Test func startNewChat_ignoresReplyToQuestionFromPreviousChat() async {
        let (sut, loader) = makeSUT()
        let sending = await startSending(to: sut, loader: loader)

        sut.startNewChat()
        loader.complete(with: .success(makeAnswer("a late answer")))
        await sending.value

        #expect(sut.turns.isEmpty)
    }

    @Test func cancel_cancelsQuestionSentAfterNewChatWhilePreviousOneWasFinishing() async {
        let (sut, loader) = makeSUT()
        let previousSending = await startSending("a previous question", to: sut, loader: loader)
        sut.startNewChat()
        let sending = await startSending(to: sut, loader: loader, at: 1)
        loader.complete(with: .failure(URLError(.cancelled)))
        await previousSending.value

        sut.cancel()
        #expect(loader.cancelledCalls == [0, 1])

        loader.complete(with: .failure(URLError(.cancelled)), at: 1)
        await sending.value
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: ChatViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = ChatViewModel(loader: loader)
        return (sut, loader)
    }

    private func replies(of sut: ChatViewModel) -> [ChatViewModel.Turn.Reply] {
        sut.turns.map(\.reply)
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
        _ question: String = "a question", to sut: ChatViewModel, loader: LoaderSpy, at index: Int = 0, completingWith result: Result<ChatAnswer, Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let sending = await startSending(question, to: sut, loader: loader, at: index, sourceLocation: sourceLocation)
        loader.complete(with: result, at: index)
        await sending.value
    }

    private final class LoaderSpy: HeldCalls<String, ChatAnswer>, ConversationLoader {
        var questions: [String] { inputs }
        private(set) var newConversationCount = 0

        init() {
            super.init(callName: "request")
        }

        func load(question: String) async throws -> ChatAnswer {
            try await call(with: question)
        }

        func startNewConversation() {
            newConversationCount += 1
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

private func anyError() -> Error {
    NSError(domain: "any error", code: 0)
}
