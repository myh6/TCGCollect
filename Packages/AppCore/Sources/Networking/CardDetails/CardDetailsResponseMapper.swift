//
//  CardDetailsResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Domain

enum CardDetailsResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> GameDetails? {
        guard response.statusCode == 200,
              let body = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
            throw Error.invalidData
        }
        return body.details?.onePieceDetails.map(GameDetails.onePiece)
    }

    private struct ResponseBody: Decodable {
        let card_id: Int
        let details: RemoteOnePieceDetails?
    }

    private struct RemoteOnePieceDetails: Decodable {
        let cardType: [String]?
        let color: [String]?
        let cost: TextNumber?
        let power: TextNumber?
        let counter: TextNumber?
        let life: TextNumber?
        let attribute: [String]?
        let subtypes: [String]?
        let description: String?

        var onePieceDetails: OnePieceDetails? {
            guard let category = cardType?.lazy.compactMap(Self.category).first else { return nil }
            return OnePieceDetails(
                category: category,
                colors: (color ?? []).compactMap { OnePieceDetails.Color(rawValue: $0.lowercased()) },
                cost: cost?.value,
                power: power?.value,
                counter: counter?.value,
                life: life?.value,
                attributes: attribute ?? [],
                types: subtypes ?? [],
                effect: effect
            )
        }

        private var effect: String? {
            let markdown = description.map(CardTextMarkdown.markdown(fromHTML:)) ?? ""
            return markdown.isEmpty ? nil : markdown
        }

        private static func category(_ cardType: String) -> OnePieceDetails.Category? {
            OnePieceDetails.Category(rawValue: cardType.lowercased().filter(\.isLetter))
        }
    }

    private struct TextNumber: Decodable {
        let value: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let number = try? container.decode(Int.self) {
                value = number
            } else {
                value = (try? container.decode(String.self)).flatMap { Int($0) }
            }
        }
    }
}
