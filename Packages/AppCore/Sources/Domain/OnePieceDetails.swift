/// Attributes specific to One Piece Card Game cards.
public struct OnePieceDetails: Hashable, Sendable {
    public enum Category: String, Hashable, Sendable {
        case leader, character, event, stage, don
    }

    public enum Color: String, Hashable, Sendable {
        case red, green, blue, purple, black, yellow
    }

    public let category: Category
    public let colors: [Color]
    public let cost: Int?
    public let power: Int?
    public let counter: Int?
    public let life: Int?
    public let attributes: [String]
    public let types: [String]
    public let effect: String?

    public init(
        category: Category,
        colors: [Color],
        cost: Int? = nil,
        power: Int? = nil,
        counter: Int? = nil,
        life: Int? = nil,
        attributes: [String] = [],
        types: [String] = [],
        effect: String? = nil
    ) {
        self.category = category
        self.colors = colors
        self.cost = cost
        self.power = power
        self.counter = counter
        self.life = life
        self.attributes = attributes
        self.types = types
        self.effect = effect
    }
}
