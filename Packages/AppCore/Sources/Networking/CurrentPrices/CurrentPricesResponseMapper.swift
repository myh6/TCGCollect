//
//  CurrentPricesResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Domain

enum CurrentPricesResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [PricePoint] {
        guard response.statusCode == 200,
              let cards = try? JSONDecoder().decode([Lossy<RemoteCard>].self, from: data) else {
            throw Error.invalidData
        }
        return cards.compactMap { $0.value?.price }
    }
}
