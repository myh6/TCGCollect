//
//  RememberingChatLoaderTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/16.
//

import Foundation
import Testing
import AppCore
import TestHelpers

struct RememberingChatLoaderTests {

    @Test func init_doesNotLoad() {
        let (_, loader) = makeSUT()

        #expect(loader.requests.isEmpty)
    }

    @Test func load_sendsFirstQuestionWithoutHistory() async throws {
        let (sut, loader) = makeSUT(results: [.success(makeAnswer("an answer"))])

        _ = try await sut.load(question: "a question")

        #expect(loader.requests == [.init(question: "a question", history: [])])
    }

    @Test func load_deliversDecorateeAnswerOnDecorateeSuccess() async throws {
        let (sut, _) = makeSUT(results: [.success(makeAnswer("an answer"))])

        let answer = try await sut.load(question: "a question")

        #expect(answer == makeAnswer("an answer"))
    }

    @Test func load_deliversDecorateeErrorOnDecorateeFailure() async {
        let error = anyNSError()
        let (sut, _) = makeSUT(results: [.failure(error)])

        await #expect(throws: error) {
            try await sut.load(question: "a question")
        }
    }

    @Test func load_sendsEveryAnsweredExchangeInOrder() async throws {
        let (sut, loader) = makeSUT(results: [.success(makeAnswer("answer 1")), .success(makeAnswer("answer 2")), .success(makeAnswer("answer 3"))])

        _ = try await sut.load(question: "question 1")
        _ = try await sut.load(question: "question 2")
        _ = try await sut.load(question: "question 3")

        #expect(loader.requests.last?.history == [
            ChatExchange(question: "question 1", answer: makeAnswer("answer 1")),
            ChatExchange(question: "question 2", answer: makeAnswer("answer 2")),
        ])
    }

    @Test func load_sendsOnlyLatestExchangesUpToHistoryLimit() async throws {
        let (sut, loader) = makeSUT(
            historyLimit: 2,
            results: [.success(makeAnswer("answer 1")), .success(makeAnswer("answer 2")), .success(makeAnswer("answer 3")), .success(makeAnswer("answer 4"))]
        )

        for number in 1...4 {
            _ = try await sut.load(question: "question \(number)")
        }

        #expect(loader.requests.last?.history == [
            ChatExchange(question: "question 2", answer: makeAnswer("answer 2")),
            ChatExchange(question: "question 3", answer: makeAnswer("answer 3")),
        ])
    }

    @Test func load_leavesFailedQuestionOutOfHistory() async throws {
        let (sut, loader) = makeSUT(results: [.success(makeAnswer("an answer")), .failure(anyNSError()), .success(makeAnswer("another answer"))])

        _ = try await sut.load(question: "a question")
        _ = try? await sut.load(question: "a failing question")
        _ = try await sut.load(question: "a follow-up")

        #expect(loader.requests.last?.history == [ChatExchange(question: "a question", answer: makeAnswer("an answer"))])
    }

    @Test func load_sendsNoHistoryAfterStartingNewConversation() async throws {
        let (sut, loader) = makeSUT(results: [.success(makeAnswer("an answer")), .success(makeAnswer("another answer"))])
        _ = try await sut.load(question: "a question")

        sut.startNewConversation()
        _ = try await sut.load(question: "a new question")

        #expect(loader.requests.last?.history == [])
    }

    // The user cancelled, so an answer that still arrives isn't part of the conversation.
    @Test func load_leavesAnswerArrivingAfterCancelOutOfHistory() async throws {
        let (sut, loader) = makeSUT(results: [.success(makeAnswer("a late answer")), .success(makeAnswer("an answer"))])
        loader.cancelsTaskOnNextCall = true
        _ = try await sut.load(question: "a cancelled question")

        _ = try await sut.load(question: "a question")

        #expect(loader.requests.last?.history == [])
    }

    // MARK: - Helpers
    private func makeSUT(historyLimit: Int = 5, results: [Result<ChatAnswer, Error>] = []) -> (sut: ConversationLoader, loader: ChatLoaderSpy) {
        let loader = ChatLoaderSpy(results: results)
        let sut = RememberingChatLoader(decoratee: loader, historyLimit: historyLimit)
        return (sut, loader)
    }

    private func makeAnswer(_ text: String) -> ChatAnswer {
        ChatAnswer(text: text, suggestions: [])
    }

    private final class ChatLoaderSpy: ChatLoader {
        struct Request: Equatable {
            let question: String
            let history: [ChatExchange]
        }

        private(set) var requests = [Request]()
        var cancelsTaskOnNextCall = false
        private var results: [Result<ChatAnswer, Error>]

        init(results: [Result<ChatAnswer, Error>]) {
            self.results = results
        }

        func load(question: String, history: [ChatExchange]) async throws -> ChatAnswer {
            requests.append(Request(question: question, history: history))
            if cancelsTaskOnNextCall {
                cancelsTaskOnNextCall = false
                withUnsafeCurrentTask { $0?.cancel() }
            }
            return try results.removeFirst().get()
        }
    }
}
