import Foundation

/// What a card is. Static catalog data, the same for every user.
public struct Card: Identifiable, Hashable, Sendable {
    public let id: String
    public let setID: String
    public let setName: String
    public let name: String
    public let imageURL: URL?
    public let rarity: String
    public let printing: String
    public let details: GameDetails

    public init(
        id: String,
        setID: String,
        setName: String,
        name: String,
        imageURL: URL?,
        rarity: String,
        printing: String,
        details: GameDetails
    ) {
        self.id = id
        self.setID = setID
        self.setName = setName
        self.name = name
        self.imageURL = imageURL
        self.rarity = rarity
        self.printing = printing
        self.details = details
    }
}
