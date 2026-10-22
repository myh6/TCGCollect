//
//  ChatResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation
import Domain

enum ChatResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    private struct AskResponse: Decodable {
        let answer: String
        let cards: [Lossy<RemoteCard>]?
    }

    /// One card in the backend's shared card shape. `details` and the price-mover extras aren't mapped yet.
    private struct RemoteCard: Decodable {
        let card_id: Int
        let name: String
        let number: String?
        let image_url: URL?
        let set_id: Int?
        let set_name: String?
        let rarity: String?
        let printing: String?
        let current_price: String
        let currency: String
        let current_fetched_at: Date

        var suggestion: ChatAnswer.Suggestion? {
            // A string, so it converts to Decimal exactly; a JSON number would go through Double first.
            guard let amount = Decimal(string: current_price, locale: Locale(identifier: "en_US_POSIX")) else { return nil }

            let card = Card(
                id: card_id,
                name: name,
                number: number,
                setID: set_id,
                setName: set_name,
                imageURL: image_url,
                rarity: rarity,
                printing: printing
            )
            let price = PricePoint(cardID: card_id, date: current_fetched_at, price: Money(amount: amount, currencyCode: currency))
            return ChatAnswer.Suggestion(card: card, price: price)
        }
    }

    /// Decodes a value without throwing, so one malformed card doesn't fail the whole answer.
    private struct Lossy<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: Decoder) throws {
            value = try? Value(from: decoder)
        }
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> ChatAnswer {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard response.statusCode == 200,
              let askResponse = try? decoder.decode(AskResponse.self, from: data) else {
            throw Error.invalidData
        }
        let suggestions = (askResponse.cards ?? []).compactMap { $0.value?.suggestion }
        return ChatAnswer(text: askResponse.answer, suggestions: suggestions)
    }
}
