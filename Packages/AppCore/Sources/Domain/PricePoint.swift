import Foundation

/// The market price of a card on a given date.
public struct PricePoint: Hashable, Sendable {
    public let cardID: Card.ID
    public let date: Date
    public let price: Money

    public init(cardID: Card.ID, date: Date, price: Money) {
        self.cardID = cardID
        self.date = date
        self.price = price
    }
}
