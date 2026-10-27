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

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> ChatAnswer {
        guard response.statusCode == 200,
              let askResponse = try? JSONDecoder().decode(AskResponse.self, from: data) else {
            throw Error.invalidData
        }
        let suggestions = (askResponse.cards ?? []).compactMap(\.value).compactMap(suggestion)
        return ChatAnswer(text: askResponse.answer, suggestions: suggestions)
    }

    /// nil for a card without a readable price, since a suggestion always shows one.
    private static func suggestion(from remoteCard: RemoteCard) -> ChatAnswer.Suggestion? {
        guard let price = remoteCard.price else { return nil }
        return ChatAnswer.Suggestion(card: remoteCard.card, price: price)
    }
}
