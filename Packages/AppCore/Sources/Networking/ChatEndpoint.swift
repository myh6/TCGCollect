//
//  ChatEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation

enum ChatEndpoint {
    case sendMessage(String)

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .sendMessage(message):
            var request = URLRequest(url: baseURL.appending(path: "v1/ask"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AskRequestBody(question: message))
            return request
        }
    }

    private struct AskRequestBody: Encodable {
        let question: String
    }
}
