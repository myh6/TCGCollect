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

    static func map(_ data: Data, from response: HTTPURLResponse, game: Game?) throws -> GameDetails? {
        guard response.statusCode == 200 else { throw Error.invalidData }
        switch game {
        case .onePiece, nil:
            return try decode(RemoteOnePieceDetails.self, from: data)?.onePieceDetails.map(GameDetails.onePiece)
        case .pokemon:
            return try decode(RemotePokemonDetails.self, from: data)?.pokemonDetails.map(GameDetails.pokemon)
        }
    }

    private static func decode<Details: Decodable>(_ type: Details.Type, from data: Data) throws -> Details? {
        guard let body = try? JSONDecoder().decode(ResponseBody<Details>.self, from: data) else {
            throw Error.invalidData
        }
        return body.details
    }

    private struct ResponseBody<Details: Decodable>: Decodable {
        let card_id: Int
        let details: Details?
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
                effect: CardTextMarkdown.nonEmptyMarkdown(fromHTML: description)
            )
        }

        private static func category(_ cardType: String) -> OnePieceDetails.Category? {
            OnePieceDetails.Category(rawValue: cardType.lowercased().filter(\.isLetter))
        }
    }

    private struct RemotePokemonDetails: Decodable {
        let cardType: [String]?
        let stage: String?
        let hp: TextNumber?
        let energyType: [String]?
        let attack1: String?
        let attack2: String?
        let attack3: String?
        let attack4: String?
        let weakness: String?
        let resistance: String?
        let retreatCost: TextNumber?
        let description: String?
        let flavorText: String?

        var pokemonDetails: PokemonDetails? {
            guard let category = cardType?.lazy.compactMap(category).first else { return nil }
            return PokemonDetails(
                category: category,
                stage: text(stage),
                hp: hp?.value,
                energyTypes: (energyType ?? []).compactMap { PokemonDetails.EnergyType(rawValue: $0.lowercased()) },
                attacks: [attack1, attack2, attack3, attack4].compactMap(CardTextMarkdown.nonEmptyMarkdown(fromHTML:)),
                weakness: text(weakness),
                resistance: text(resistance),
                retreatCost: retreatCost?.value,
                effect: CardTextMarkdown.nonEmptyMarkdown(fromHTML: description),
                flavorText: text(flavorText)
            )
        }

        private func category(_ cardType: String) -> PokemonDetails.Category? {
            PokemonDetails.Category(rawValue: cardType.lowercased().filter(\.isLetter))
        }

        private func text(_ value: String?) -> String? {
            let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return text.isEmpty || text.lowercased() == "none" ? nil : text
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
