//
//  CardDetailsEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

enum CardDetailsEndpoint {
    case details(cardID: Int)

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .details(cardID):
            var request = URLRequest(url: baseURL.appending(path: "v1/cards/details"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(DetailsRequestBody(card_id: cardID))
            return request
        }
    }

    private struct DetailsRequestBody: Encodable {
        let card_id: Int
    }
}
