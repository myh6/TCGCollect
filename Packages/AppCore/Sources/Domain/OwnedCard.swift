import Foundation

/// One copy of a card that the user owns.
public struct OwnedCard: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let card: Card
    public var purchasePrice: Money?
    public var acquiredOn: Date?

    public init(id: UUID = UUID(), card: Card, purchasePrice: Money? = nil, acquiredOn: Date? = nil) {
        self.id = id
        self.card = card
        self.purchasePrice = purchasePrice
        self.acquiredOn = acquiredOn
    }
}
