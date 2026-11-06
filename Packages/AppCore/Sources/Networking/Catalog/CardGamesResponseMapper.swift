//
//  CardGamesResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Domain

enum CardGamesResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [CardGame] {
        guard response.statusCode == 200,
              let games = try? JSONDecoder().decode([Lossy<RemoteGame>].self, from: data) else {
            throw Error.invalidData
        }
        return games.compactMap(\.value).map { CardGame(slug: $0.slug, name: $0.name) }
    }

    private struct RemoteGame: Decodable {
        let slug: String
        let name: String
    }
}
