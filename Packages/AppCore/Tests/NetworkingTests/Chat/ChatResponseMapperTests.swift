import Testing
@testable import Networking
import TestHelpers
import Domain

import Foundation

struct ChatResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(makeAnswerJSON("an answer"), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)

        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(invalidJSON, from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAnswer() {
        let json = Data(#"{"cards": []}"#.utf8)

        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(json, from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversAnswerWithoutSuggestionsOn200HTTPResponseWithEmptyCards() throws {
        let answer = try ChatResponseMapper.map(makeAnswerJSON("an answer", cards: []), from: httpResponse(statusCode: 200))

        #expect(answer == ChatAnswer(text: "an answer", suggestions: []))
    }

    @Test(arguments: [#"{"answer": "an answer"}"#, #"{"answer": "an answer", "cards": null}"#])
    func map_deliversAnswerWithoutSuggestionsOn200HTTPResponseWithoutCards(json: String) throws {
        let answer = try ChatResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))

        #expect(answer == ChatAnswer(text: "an answer", suggestions: []))
    }

    @Test func map_deliversSuggestionsInBackendOrderOn200HTTPResponseWithCards() throws {
        let card0 = makeCard(id: 0, name: "a card")
        let card1 = makeCard(
            id: 1,
            name: "another card",
            number: "OP01-001",
            setID: 2,
            setName: "a set",
            imageURL: URL(string: "https://an-image.com/card.png"),
            rarity: "L",
            printing: "a printing",
            price: "1234.50",
            currency: "JPY",
            fetchedAt: (Date(timeIntervalSince1970: 1_767_225_600), "2026-01-01T00:00:00+00:00")
        )

        let answer = try ChatResponseMapper.map(
            makeAnswerJSON("an answer", cards: [card0.json, card1.json]),
            from: httpResponse(statusCode: 200)
        )

        #expect(answer == ChatAnswer(text: "an answer", suggestions: [card0.model, card1.model]))
    }

    @Test func map_deliversSuggestionWithoutOptionalValuesWhenTheirKeysAreMissing() throws {
        let card = makeCard(id: 0, name: "a card")
        let json = card.json.filter { !($0.value is NSNull) }

        let answer = try ChatResponseMapper.map(makeAnswerJSON("an answer", cards: [json]), from: httpResponse(statusCode: 200))

        #expect(answer.suggestions == [card.model])
    }

    @Test func map_convertsFetchedAtWithTimeZoneOffsetToTheSameInstant() throws {
        let card = makeCard(id: 0, name: "a card", fetchedAt: (Date(timeIntervalSince1970: 1_767_225_600), "2026-01-01T09:00:00+09:00"))

        let answer = try ChatResponseMapper.map(makeAnswerJSON("an answer", cards: [card.json]), from: httpResponse(statusCode: 200))

        #expect(answer.suggestions == [card.model])
    }

    // The backend reserves `details` but doesn't fill it yet; whatever it sends mustn't drop the card.
    @Test func map_deliversSuggestionWithoutDetailsWhenBackendSendsDetails() throws {
        let card = makeCard(id: 0, name: "a card")
        var json = card.json
        json["details"] = ["power": 5000]

        let answer = try ChatResponseMapper.map(makeAnswerJSON("an answer", cards: [json]), from: httpResponse(statusCode: 200))

        #expect(answer.suggestions == [card.model])
    }

    @Test(arguments: ["card_id", "name", "current_price", "currency", "current_fetched_at"])
    func map_skipsOnlyTheCardMissingARequiredValue(key: String) throws {
        let validCard = makeCard(id: 0, name: "a card")
        var invalidJSON = makeCard(id: 1, name: "another card").json
        invalidJSON[key] = nil

        let answer = try ChatResponseMapper.map(
            makeAnswerJSON("an answer", cards: [invalidJSON, validCard.json]),
            from: httpResponse(statusCode: 200)
        )

        #expect(answer == ChatAnswer(text: "an answer", suggestions: [validCard.model]))
    }

    @Test(arguments: [
        ("card_id", "not an id"),
        ("current_price", "not a price"),
        ("current_fetched_at", "not a date"),
    ])
    func map_skipsOnlyTheCardWithAnInvalidRequiredValue(key: String, value: String) throws {
        let validCard = makeCard(id: 0, name: "a card")
        var invalidJSON = makeCard(id: 1, name: "another card").json
        invalidJSON[key] = value

        let answer = try ChatResponseMapper.map(
            makeAnswerJSON("an answer", cards: [invalidJSON, validCard.json]),
            from: httpResponse(statusCode: 200)
        )

        #expect(answer == ChatAnswer(text: "an answer", suggestions: [validCard.model]))
    }

    // MARK: - Helpers
    private func makeAnswerJSON(_ answer: String, cards: [[String: Any]] = []) -> Data {
        let json: [String: Any] = ["answer": answer, "cards": cards]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    /// A card as the backend sends it, with the suggestion it should map to. Optional values are sent as null.
    private func makeCard(
        id: Int,
        name: String,
        number: String? = nil,
        setID: Int? = nil,
        setName: String? = nil,
        imageURL: URL? = nil,
        rarity: String? = nil,
        printing: String? = nil,
        price: String = "9.99",
        currency: String = "USD",
        fetchedAt: (date: Date, iso8601: String) = (Date(timeIntervalSince1970: 1_767_225_600), "2026-01-01T00:00:00+00:00")
    ) -> (model: ChatAnswer.Suggestion, json: [String: Any]) {
        let card = Card(
            id: id,
            name: name,
            number: number,
            setID: setID,
            setName: setName,
            imageURL: imageURL,
            rarity: rarity,
            printing: printing
        )
        let pricePoint = PricePoint(
            cardID: id,
            date: fetchedAt.date,
            price: Money(amount: Decimal(string: price)!, currencyCode: currency)
        )
        let json: [String: Any] = [
            "card_id": id,
            "name": name,
            "number": number ?? NSNull(),
            "image_url": imageURL?.absoluteString ?? NSNull(),
            "set_id": setID ?? NSNull(),
            "set_name": setName ?? NSNull(),
            "rarity": rarity ?? NSNull(),
            "printing": printing ?? NSNull(),
            "game_slug": "one-piece-card-game",
            "current_price": price,
            "current_fetched_at": fetchedAt.iso8601,
            "currency": currency,
            "details": NSNull(),
            "pct_change": NSNull(),
            "baseline_price": NSNull(),
            "baseline_fetched_at": NSNull(),
        ]
        return (ChatAnswer.Suggestion(card: card, price: pricePoint), json)
    }
}
