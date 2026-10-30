//
//  PriceHistoryEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

enum PriceHistoryEndpoint {
    case history(cardIDs: [Int], days: Int?)

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .history(cardIDs, days):
            var request = URLRequest(url: baseURL.appending(path: "v1/prices/history"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(HistoryRequestBody(card_ids: cardIDs, days: days))
            return request
        }
    }

    private struct HistoryRequestBody: Encodable {
        let card_ids: [Int]
        let days: Int?
    }
}
