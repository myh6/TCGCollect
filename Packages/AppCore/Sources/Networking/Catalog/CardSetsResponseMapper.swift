//
//  CardSetsResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Domain

enum CardSetsResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [CardSet] {
        guard response.statusCode == 200,
              let sets = try? JSONDecoder().decode([Lossy<RemoteSet>].self, from: data) else {
            throw Error.invalidData
        }
        return sets.compactMap(\.value?.set)
    }

    private struct RemoteSet: Decodable {
        let set_id: Int
        let name: String
        let card_count: Int
        let released_on: String?
        let set_icon_url: String?

        var set: CardSet {
            CardSet(
                id: set_id,
                name: name,
                cardCount: card_count,
                releaseDate: released_on.flatMap(RemoteDay.startOfDay),
                iconURL: set_icon_url.flatMap(URL.init(string:))
            )
        }
    }
}
