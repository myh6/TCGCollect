//
//  CardSearchResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Domain

enum CardSearchResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [CardSearchResult] {
        guard response.statusCode == 200,
              let cards = try? JSONDecoder().decode([Lossy<RemoteCard>].self, from: data) else {
            throw Error.invalidData
        }
        return cards.compactMap(\.value).map { CardSearchResult(card: $0.card, price: $0.price) }
    }
}
