//
//  RemoteLoader+ChatLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

extension RemoteLoader: ChatLoader where Input == (question: String, history: [ChatExchange]), Resource == ChatAnswer {
    public func load(question: String, history: [ChatExchange]) async throws -> ChatAnswer {
        try await load((question, history))
    }
}
