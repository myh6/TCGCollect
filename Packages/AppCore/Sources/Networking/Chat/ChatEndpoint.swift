//
//  ChatEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation
import Domain

enum ChatEndpoint {
    case sendMessage(String, history: [ChatExchange])

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .sendMessage(message, history):
            var request = URLRequest(url: baseURL.appending(path: "v1/ask"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AskRequestBody(question: message, history: history.flatMap(turns)))
            return request
        }
    }

    private func turns(of exchange: ChatExchange) -> [HistoryTurn] {
        [HistoryTurn(role: "user", text: exchange.question), HistoryTurn(role: "assistant", text: exchange.answer.text)]
    }

    private struct AskRequestBody: Encodable {
        let question: String
        let history: [HistoryTurn]
    }

    private struct HistoryTurn: Encodable {
        let role: String
        let text: String
    }
}
