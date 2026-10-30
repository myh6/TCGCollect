//
//  CurrentPricesEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

enum CurrentPricesEndpoint {
    case prices(cardIDs: [Int])

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .prices(cardIDs):
            var request = URLRequest(url: baseURL.appending(path: "v1/prices/current"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(PricesRequestBody(card_ids: cardIDs))
            return request
        }
    }

    private struct PricesRequestBody: Encodable {
        let card_ids: [Int]
    }
}
