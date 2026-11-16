//
//  RememberingChatLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/16.
//

import Domain
import Networking

/// Sends each question with the latest answered exchanges, so the backend can follow the conversation.
public final class RememberingChatLoader: ConversationLoader {
    private let decoratee: ChatLoader
    private let historyLimit: Int
    private var history = [ChatExchange]()

    public init(decoratee: ChatLoader, historyLimit: Int = 5) {
        self.decoratee = decoratee
        self.historyLimit = historyLimit
    }

    public func load(question: String) async throws -> ChatAnswer {
        let answer = try await decoratee.load(question: question, history: history)
        // The user cancelled, so an answer that still arrives isn't part of the conversation.
        if !Task.isCancelled {
            history = Array((history + [ChatExchange(question: question, answer: answer)]).suffix(historyLimit))
        }
        return answer
    }
}
