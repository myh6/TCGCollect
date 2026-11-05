//
//  CollectionValueEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation

enum CollectionValueEndpoint {
    case history(quantities: [Int: Int], days: Int?)

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .history(quantities, days):
            var request = URLRequest(url: baseURL.appending(path: "v1/collections/value-history"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let cards = quantities.sorted { $0.key < $1.key }.map { CardQuantity(card_id: $0.key, quantity: $0.value) }
            request.httpBody = try JSONEncoder().encode(HistoryRequestBody(cards: cards, days: days))
            return request
        }
    }

    private struct HistoryRequestBody: Encodable {
        let cards: [CardQuantity]
        let days: Int?
    }

    private struct CardQuantity: Encodable {
        let card_id: Int
        let quantity: Int
    }
}
