//
//  ChatViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Observation
import AppCore

/// The questions asked so far and their replies, one question at a time.
@MainActor
@Observable
final class ChatViewModel {
    struct Turn: Identifiable, Equatable {
        enum Reply: Equatable {
            case waiting
            case answered(ChatAnswer)
            case failed(ChatError)
            case cancelled
        }

        let id: Int
        let question: String
        fileprivate(set) var reply: Reply

        var canRetry: Bool {
            switch reply {
            case .failed, .cancelled: true
            case .waiting, .answered: false
            }
        }
    }

    private(set) var turns = [Turn]()

    var isWaitingForAnswer: Bool {
        turns.contains { $0.reply == .waiting }
    }

    private let loader: ConversationLoader
    private var loadTask: Task<ChatAnswer, Error>?
    private var nextTurnID = 0

    init(loader: ConversationLoader) {
        self.loader = loader
    }

    func send(_ question: String) async {
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isWaitingForAnswer else { return }

        let turnID = nextTurnID
        nextTurnID += 1
        turns.append(Turn(id: turnID, question: question, reply: .waiting))
        // Its own task, so cancel() can stop it; URLSession cancels the network request with it.
        let task = Task { [loader] in try await loader.load(question: question) }
        loadTask = task
        defer { loadTask = nil }

        let reply: Turn.Reply
        do {
            let answer = try await task.value
            // The user cancelled, so drop an answer that still arrived.
            reply = task.isCancelled ? .cancelled : .answered(answer)
        } catch {
            // Whatever the loader throws after a cancel, the user asked for it: not an error to show.
            reply = task.isCancelled ? .cancelled : .failed(.couldNotLoadAnswer)
        }
        if let index = turns.firstIndex(where: { $0.id == turnID }) {
            turns[index].reply = reply
        }
    }

    /// Asks a failed or cancelled question again, moving it to the end of the conversation.
    func retry(_ turn: Turn) async {
        guard !isWaitingForAnswer, let index = turns.firstIndex(where: { $0.id == turn.id }), turns[index].canRetry else { return }
        turns.remove(at: index)
        await send(turn.question)
    }

    /// Stops the request in progress and marks its question as cancelled. Does nothing when there is none.
    func cancel() {
        loadTask?.cancel()
    }
}
