//
//  CardDetailPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import Foundation
import AppCore
import HoloCard

nonisolated struct CardDetailPresentation: Identifiable, Hashable {
    let id: Card.ID
    let name: String
    let details: String?
    let setName: String?
    let printing: String?
    let imageURL: URL?
    let holoStyle: HoloStyle
    let card: Card

    init(_ card: Card) {
        id = card.id
        name = card.name
        details = card.numberAndRarity
        setName = card.setName
        printing = card.printing
        imageURL = card.imageURL
        holoStyle = card.holoStyle
        self.card = card
    }
}
