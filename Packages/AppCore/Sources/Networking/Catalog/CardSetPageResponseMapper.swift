//
//  CardSetPageResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Domain

enum CardSetPageResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> CardSetPage {
        guard response.statusCode == 200,
              let body = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
            throw Error.invalidData
        }
        return CardSetPage(
            cards: body.cards.compactMap(\.value).map { CardSearchResult(card: $0.card, price: $0.price) },
            totalCount: body.total
        )
    }

    private struct ResponseBody: Decodable {
        let cards: [Lossy<RemoteCard>]
        let total: Int
    }
}
