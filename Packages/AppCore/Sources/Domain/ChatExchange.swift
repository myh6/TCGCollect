//
//  ChatExchange.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/12.
//

public struct ChatExchange: Hashable, Sendable {
    public let question: String
    public let answer: ChatAnswer

    public init(question: String, answer: ChatAnswer) {
        self.question = question
        self.answer = answer
    }
}
