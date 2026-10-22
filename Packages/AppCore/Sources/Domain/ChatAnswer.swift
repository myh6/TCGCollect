/// The backend's answer to a question, with the cards it found along the way.
public struct ChatAnswer: Hashable, Sendable {
    /// A card the answer refers to, with its current market price.
    public struct Suggestion: Hashable, Sendable {
        public let card: Card
        public let price: PricePoint

        public init(card: Card, price: PricePoint) {
            self.card = card
            self.price = price
        }
    }

    public let text: String
    public let suggestions: [Suggestion]

    public init(text: String, suggestions: [Suggestion]) {
        self.text = text
        self.suggestions = suggestions
    }
}
