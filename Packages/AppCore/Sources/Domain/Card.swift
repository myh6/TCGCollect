import Foundation

/// What a card is. Static catalog data, the same for every user.
/// Everything but `id` and `name` is optional: the backend doesn't know it for every card.
public struct Card: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let number: String?
    public let setID: Int?
    public let setName: String?
    public let imageURL: URL?
    public let rarity: String?
    public let printing: String?

    public init(
        id: Int,
        name: String,
        number: String? = nil,
        setID: Int? = nil,
        setName: String? = nil,
        imageURL: URL? = nil,
        rarity: String? = nil,
        printing: String? = nil
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.setID = setID
        self.setName = setName
        self.imageURL = imageURL
        self.rarity = rarity
        self.printing = printing
    }
}
