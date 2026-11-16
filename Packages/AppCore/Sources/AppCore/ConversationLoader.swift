//
//  ConversationLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/16.
//

import Domain

public protocol ConversationLoader {
    func load(question: String) async throws -> ChatAnswer
}
