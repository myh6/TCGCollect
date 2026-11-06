//
//  CatalogEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation

enum CatalogEndpoint {
    case games
    case sets(gameSlug: String)
    case cards(setID: Int, limit: Int = 50, offset: Int)

    func urlRequest(baseURL: URL) -> URLRequest {
        switch self {
        case .games:
            URLRequest(url: baseURL.appending(path: "v1/catalog/games"))
        case let .sets(gameSlug):
            URLRequest(url: baseURL.appending(path: "v1/catalog/games/\(gameSlug)/sets"))
        case let .cards(setID, limit, offset):
            URLRequest(url: baseURL
                .appending(path: "v1/catalog/sets/\(setID)/cards")
                .appending(queryItems: [URLQueryItem(name: "limit", value: "\(limit)"), URLQueryItem(name: "offset", value: "\(offset)")]))
        }
    }
}
