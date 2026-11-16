//
//  ChatViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Observation
import AppCore

/// Sends one question at a time to the backend and holds its latest answer.
@MainActor
@Observable
final class ChatViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(answer: ChatAnswer)
        case failed(ChatError)
    }

    private(set) var state = State.idle

    private let loader: ChatLoader
    private var loadTask: Task<ChatAnswer, Error>?
    private var history = [ChatExchange]()
    private let historyLimit: Int

    init(loader: ChatLoader, historyLimit: Int = 5) {
        self.loader = loader
        self.historyLimit = historyLimit
    }

    func send(_ question: String) async {
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, state != .loading else { return }

        let stateBeforeSending = state
        state = .loading
        // Its own task, so cancel() can stop it; URLSession cancels the network request with it.
        let task = Task { [loader, history] in try await loader.load(question: question, history: history) }
        loadTask = task
        defer { loadTask = nil }

        do {
            let answer = try await task.value
            // The user cancelled, so drop an answer that still arrived.
            guard !task.isCancelled else {
                state = stateBeforeSending
                return
            }
            state = .loaded(answer: answer)
            history = Array((history + [ChatExchange(question: question, answer: answer)]).suffix(historyLimit))
        } catch {
            // Whatever the loader throws after a cancel, the user asked for it: not an error to show.
            guard !task.isCancelled else {
                state = stateBeforeSending
                return
            }
            state = .failed(.couldNotLoadAnswer)
        }
    }

    /// Stops the request in progress and goes back to what was shown before it. Does nothing when there is none.
    func cancel() {
        loadTask?.cancel()
    }
}
