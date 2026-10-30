//
//  PriceHistoryResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Domain

enum PriceHistoryResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [PricePoint] {
        guard response.statusCode == 200,
              let rows = try? JSONDecoder().decode([Lossy<Row>].self, from: data) else {
            throw Error.invalidData
        }
        return rows.compactMap(\.value?.pricePoint)
    }

    private struct Row: Decodable {
        let card_id: Int
        let market_price: String?
        let currency: String?
        let fetched_at: String?

        var pricePoint: PricePoint? {
            RemotePricePoint.make(cardID: card_id, amount: market_price, currency: currency, fetchedAt: fetched_at)
        }
    }
}
