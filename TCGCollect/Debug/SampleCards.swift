//
//  SampleCards.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

#if DEBUG
import Foundation
import AppCore

enum SampleCards {
    static var isOn: Bool {
        ProcessInfo.processInfo.arguments.contains("-sampleCards")
    }

    static let cards = [
        Card(
            id: 676552, name: "Shanks", number: "ST05-001", setName: "ST-05: Starter Deck 5 Film Edition",
            imageURL: URL(string: "https://product-images.tcgplayer.com/fit-in/400x400/477316.jpg"),
            rarity: "L", printing: "Foil"
        ),
        Card(
            id: 2133087, name: "Luffy & Ace", number: "ST30-001", setName: "ST-30: Starter Deck 30 EX Luffy & Ace",
            imageURL: URL(string: "https://product-images.tcgplayer.com/fit-in/400x400/693256.jpg"),
            rarity: "L", printing: "Foil"
        ),
        Card(
            id: 676897, name: "Nami", number: "ST01-007", setName: "ST-01: Starter Deck 1 Straw Hat Crew",
            imageURL: URL(string: "https://product-images.tcgplayer.com/fit-in/400x400/288236.jpg"),
            rarity: "C", printing: "Normal"
        ),
    ]

    static let details: [Card.ID: GameDetails] = [
        676552: .onePiece(OnePieceDetails(
            category: .leader, colors: [.purple], power: 5000, life: 5,
            attributes: ["Slash"], types: ["FILM", "The Four Emperors", "Red-Haired Pirates"],
            effect: "[Activate: Main] [Once Per Turn] DON!! −3 *(You may return the specified number of DON!! cards from your field to your DON!! deck.)*: All of your {FILM} type Characters gain +2000 power during this turn."
        )),
        2133087: .onePiece(OnePieceDetails(
            category: .leader, colors: [.red, .green], power: 6000, life: 4,
            attributes: ["Strike", "Special"], types: ["Impel Down", "Whitebeard Pirates", "Straw Hat Crew"],
            effect: "If you have a Character with 7000 base power or more, give this Leader −2000 power.\n[Opponent's Turn] All of your [Portgas.D.Ace] and [Monkey.D.Luffy] cards gain +3000 power."
        )),
    ]

    static func addMissing(to collection: OwnedCardCollection) async {
        let ownedIDs = Set(((try? await collection.load()) ?? []).map(\.card.id))
        let missing = cards.filter { !ownedIDs.contains($0.id) }.map { OwnedCard(card: $0) }
        guard !missing.isEmpty else { return }
        try? await collection.save(missing)
    }
}

struct SampleCardDetailsLoader: CardDetailsLoader {
    func loadDetails(for cardID: Card.ID) async throws -> GameDetails? {
        SampleCards.details[cardID]
    }
}
#endif
